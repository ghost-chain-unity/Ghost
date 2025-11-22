# S3 Storage Module

This module provisions multiple S3 buckets with encryption, versioning, lifecycle policies, cross-region replication, and optional CloudFront CDN for static assets.

## Features

- **Multiple Buckets**: Application data, backups, logs, and static assets
- **KMS Encryption**: All buckets encrypted at rest using customer-managed KMS keys
- **Versioning**: Object versioning enabled for data protection
- **Public Access Block**: All public access blocked by default
- **Lifecycle Policies**: Automatic transition to Glacier and Deep Archive
- **Access Logging**: S3 access logs for security auditing
- **Cross-Region Replication**: Disaster recovery for backup and logs buckets
- **Object Lock**: WORM (Write-Once-Read-Many) for compliance
- **CloudFront CDN**: Optional CDN for static assets with OAI and SSL
- **Bucket Policies**: Enforce SSL/TLS and deny unencrypted uploads

## Architecture

```
┌─────────────────── S3 Buckets ──────────────────────┐
│                                                      │
│  Application Data Bucket                            │
│  ├─ User uploads, assets                            │
│  ├─ Versioning: Enabled                             │
│  ├─ Lifecycle: STANDARD → STANDARD_IA (30d)         │
│  │            → GLACIER (90d) → Expire (365d)       │
│  └─ Replication: None                               │
│                                                      │
│  Backup Bucket                                       │
│  ├─ Database backups, snapshots                     │
│  ├─ Versioning: Enabled                             │
│  ├─ Lifecycle: STANDARD → GLACIER (30d)             │
│  │            → DEEP_ARCHIVE (90d) → Expire (365d)  │
│  ├─ Replication: us-east-1 → us-west-2              │
│  └─ Object Lock: Optional (WORM compliance)         │
│                                                      │
│  Logs Bucket                                         │
│  ├─ Application logs, S3 access logs                │
│  ├─ Versioning: Enabled                             │
│  ├─ Lifecycle: STANDARD → GLACIER (90d)             │
│  │            → Expire (365d)                        │
│  └─ Replication: us-east-1 → us-west-2              │
│                                                      │
│  Static Assets Bucket                                │
│  ├─ Frontend builds, public files                   │
│  ├─ Versioning: Enabled                             │
│  ├─ CloudFront: Optional CDN                        │
│  └─ OAI: Secure access from CloudFront only         │
│                                                      │
└──────────────────────────────────────────────────────┘

┌─────────────── CloudFront CDN (Optional) ───────────┐
│                                                      │
│  Domain: d1234abcd.cloudfront.net                   │
│  Origin: static-assets-bucket.s3.amazonaws.com      │
│  SSL: ACM certificate (TLS 1.2+)                    │
│  Caching: 1 day default TTL                         │
│  Geo-restriction: Configurable                      │
│  OAI: Secure S3 access                              │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Usage

### Basic Example (Development)

```hcl
module "storage_dev" {
  source = "./modules/storage/aws"

  project_name = "ghost-protocol"
  environment  = "dev"
  aws_region   = "us-east-1"

  kms_key_arn = module.observability.kms_s3_key_arn

  enable_versioning           = true
  block_public_access         = true
  enable_access_logging       = true
  enable_cross_region_replication = false
  enable_cloudfront           = false

  tags = {
    Environment = "development"
    Project     = "ghost-protocol"
  }
}
```

### Production Example with Replication

```hcl
module "storage_prod" {
  source = "./modules/storage/aws"

  project_name = "ghost-protocol"
  environment  = "prod"
  aws_region   = "us-east-1"

  kms_key_arn = module.observability.kms_s3_key_arn

  enable_versioning           = true
  block_public_access         = true
  enable_access_logging       = true
  enable_cross_region_replication = true
  enable_backup_replication   = true
  enable_logs_replication     = true

  replication_destination_region         = "us-west-2"
  replication_destination_kms_key_arn    = var.dr_region_kms_key_arn
  replication_storage_class              = "STANDARD_IA"

  enable_backup_object_lock   = true
  object_lock_mode            = "COMPLIANCE"
  object_lock_retention_days  = 365

  allowed_role_arns = [
    module.observability.api_gateway_pod_role_arn,
    module.observability.indexer_pod_role_arn
  ]

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
  }
}
```

### Production with CloudFront CDN

```hcl
module "storage_prod_cdn" {
  source = "./modules/storage/aws"

  project_name = "ghost-protocol"
  environment  = "prod"
  aws_region   = "us-east-1"

  kms_key_arn = module.observability.kms_s3_key_arn

  enable_cloudfront           = true
  cloudfront_aliases          = ["cdn.ghostprotocol.io"]
  cloudfront_acm_certificate_arn = var.acm_certificate_arn
  cloudfront_price_class      = "PriceClass_100"
  cloudfront_default_ttl      = 86400
  cloudfront_max_ttl          = 31536000

  cloudfront_custom_cache_behaviors = [
    {
      path_pattern         = "/static/*"
      allowed_methods      = ["GET", "HEAD"]
      cached_methods       = ["GET", "HEAD"]
      forward_query_string = false
      default_ttl          = 2592000  # 30 days
    }
  ]

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
  }
}
```

### Custom Lifecycle Rules

```hcl
module "storage_custom_lifecycle" {
  source = "./modules/storage/aws"

  project_name = "ghost-protocol"
  environment  = "prod"
  aws_region   = "us-east-1"

  kms_key_arn = module.observability.kms_s3_key_arn

  backup_lifecycle_rules = [
    {
      id      = "daily-backups"
      enabled = true
      prefix  = "daily/"
      transitions = [
        {
          days          = 7
          storage_class = "GLACIER"
        }
      ]
      expiration_days = 30
    },
    {
      id      = "monthly-backups"
      enabled = true
      prefix  = "monthly/"
      transitions = [
        {
          days          = 30
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration_days = 365
    }
  ]

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
  }
}
```

## Bucket Usage Guide

### Application Data Bucket

**Purpose**: User uploads, media files, application assets

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3 = new S3Client({ region: 'us-east-1' });

async function uploadFile(file: Buffer, key: string) {
  await s3.send(new PutObjectCommand({
    Bucket: process.env.APP_DATA_BUCKET,
    Key: key,
    Body: file,
    ServerSideEncryption: 'aws:kms',
    SSEKMSKeyId: process.env.KMS_KEY_ARN
  }));
}
```

### Backup Bucket

**Purpose**: Database backups, snapshots

```bash
# Backup PostgreSQL to S3
pg_dump -h <rds-endpoint> -U ghostadmin -d ghostprotocol \
  --format=custom \
  | aws s3 cp - s3://ghost-protocol-prod-backups/db/backup-$(date +%Y%m%d).dump \
    --server-side-encryption aws:kms \
    --ssekms-key-id $KMS_KEY_ARN

# Restore from S3
aws s3 cp s3://ghost-protocol-prod-backups/db/backup-20251116.dump - \
  | pg_restore -h <rds-endpoint> -U ghostadmin -d ghostprotocol
```

### Logs Bucket

**Purpose**: Application logs, audit logs, S3 access logs

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

async function uploadLog(logData: string, timestamp: string) {
  const key = `application-logs/${timestamp}.log`;
  await s3.send(new PutObjectCommand({
    Bucket: process.env.LOGS_BUCKET,
    Key: key,
    Body: logData,
    ServerSideEncryption: 'aws:kms'
  }));
}
```

### Static Assets Bucket

**Purpose**: Frontend builds, public assets

```bash
# Deploy Next.js build to S3
npm run build
aws s3 sync out/ s3://ghost-protocol-prod-static-assets/ \
  --delete \
  --server-side-encryption aws:kms \
  --cache-control "public, max-age=31536000, immutable"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_ID \
  --paths "/*"
```

## Cross-Region Replication

### Prerequisites

1. Create destination buckets in target region (us-west-2):

```bash
aws s3api create-bucket \
  --bucket ghost-protocol-prod-backups-replica \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-bucket-versioning \
  --bucket ghost-protocol-prod-backups-replica \
  --versioning-configuration Status=Enabled
```

2. Create KMS key in destination region for encryption

### Verification

```bash
# Check replication status
aws s3api get-bucket-replication --bucket ghost-protocol-prod-backups

# Monitor replication metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name ReplicationLatency \
  --dimensions Name=SourceBucket,Value=ghost-protocol-prod-backups \
  --start-time 2025-11-16T00:00:00Z \
  --end-time 2025-11-16T23:59:59Z \
  --period 3600 \
  --statistics Average
```

## CloudFront CDN Setup

### DNS Configuration

```hcl
resource "aws_route53_record" "cdn" {
  zone_id = var.hosted_zone_id
  name    = "cdn.ghostprotocol.io"
  type    = "A"

  alias {
    name                   = module.storage.cloudfront_domain_name
    zone_id                = module.storage.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
```

### ACM Certificate (us-east-1)

```bash
aws acm request-certificate \
  --domain-name cdn.ghostprotocol.io \
  --validation-method DNS \
  --region us-east-1
```

### Usage in Frontend

```typescript
// Next.js configuration
module.exports = {
  assetPrefix: process.env.NODE_ENV === 'production' 
    ? 'https://cdn.ghostprotocol.io'
    : '',
  images: {
    domains: ['cdn.ghostprotocol.io']
  }
};
```

## Monitoring & Alerts

### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  alarm_name          = "ghost-protocol-prod-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = "1099511627776"  # 1TB
  alarm_description   = "S3 bucket size exceeded 1TB"
  dimensions = {
    BucketName  = "ghost-protocol-prod-app-data"
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  alarm_name          = "ghost-protocol-prod-replication-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = "900"
  statistic           = "Maximum"
  threshold           = "900"  # 15 minutes
  alarm_description   = "S3 replication latency high"
  dimensions = {
    SourceBucket      = "ghost-protocol-prod-backups"
    DestinationBucket = "ghost-protocol-prod-backups-replica"
  }
}
```

## Security Best Practices

1. **Enforce Encryption**: All uploads must use KMS encryption
2. **Block Public Access**: Never allow public buckets
3. **Use SSL/TLS**: Enforce HTTPS for all requests
4. **Enable Versioning**: Protect against accidental deletion
5. **Least Privilege**: Grant minimum required permissions
6. **Object Lock**: Use WORM for compliance requirements
7. **Access Logging**: Monitor all bucket access
8. **MFA Delete**: Enable for critical buckets

## Cost Optimization

### Storage Classes

- **STANDARD**: Frequently accessed data (< 30 days old)
- **STANDARD_IA**: Infrequently accessed (30-90 days old)
- **GLACIER**: Archive storage (90+ days old)
- **DEEP_ARCHIVE**: Long-term archive (1+ year old)

### Lifecycle Policy Example

```hcl
backup_lifecycle_rules = [
  {
    id      = "optimize-costs"
    enabled = true
    transitions = [
      { days = 30,  storage_class = "GLACIER" },
      { days = 90,  storage_class = "DEEP_ARCHIVE" }
    ]
    expiration_days = 2555  # 7 years
  }
]
```

### CloudFront Cost

- **PriceClass_100**: US, Canada, Europe (cheapest)
- **PriceClass_200**: Add Asia, South Africa, South America
- **PriceClass_All**: All edge locations (most expensive)

## Troubleshooting

### Access Denied Errors

```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket ghost-protocol-prod-app-data

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/api-gateway-pod-role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::ghost-protocol-prod-app-data/*
```

### Replication Not Working

```bash
# Check replication configuration
aws s3api get-bucket-replication --bucket ghost-protocol-prod-backups

# Check replication role permissions
aws iam get-role-policy \
  --role-name ghost-protocol-prod-s3-replication-role \
  --policy-name replication-policy
```

### CloudFront Cache Issues

```bash
# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id E1234ABCD5678 \
  --paths "/*"

# Check distribution status
aws cloudfront get-distribution --id E1234ABCD5678
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | "ghost-protocol" | no |
| environment | Environment (dev/staging/prod) | string | - | yes |
| kms_key_arn | KMS key ARN | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket_ids | Map of bucket IDs |
| bucket_arns | Map of bucket ARNs |
| cloudfront_domain_name | CloudFront domain |

## License

MIT
