# RDS PostgreSQL Database Module

This module provisions an Amazon RDS PostgreSQL instance with optional read replicas, optimized parameter groups, and comprehensive monitoring.

## Features

- **PostgreSQL 15+**: Latest stable PostgreSQL version
- **Multi-AZ Deployment**: High availability for production
- **Storage Auto-Scaling**: gp3 storage with automatic expansion
- **Encryption**: At-rest encryption using KMS
- **SSL/TLS**: Enforced secure connections
- **Automated Backups**: Configurable retention (7-35 days)
- **Enhanced Monitoring**: 60-second interval CloudWatch metrics
- **Performance Insights**: Query-level performance monitoring
- **Read Replicas**: Optional same-region and cross-region replicas
- **CloudWatch Logs**: PostgreSQL and upgrade logs exported

## Architecture

```
┌─────────────────── RDS PostgreSQL ───────────────────┐
│                                                       │
│  Primary Instance (Multi-AZ)                         │
│  ├─ us-east-1a: Primary                              │
│  └─ us-east-1b: Standby (automatic failover)         │
│                                                       │
│  Storage: gp3 (3000 IOPS, 125 MB/s)                  │
│  ├─ Auto-scaling: 20GB → 100GB                       │
│  └─ Encrypted: KMS (rds-key)                         │
│                                                       │
│  Backups                                              │
│  ├─ Automated snapshots (daily, 02:00-04:00 UTC)     │
│  ├─ Retention: 7-35 days                             │
│  └─ Point-in-time recovery (PITR)                    │
│                                                       │
│  Read Replicas (Optional)                            │
│  ├─ Same-region: 1-5 replicas (scaling reads)        │
│  └─ Cross-region: us-west-2 (disaster recovery)      │
│                                                       │
│  Monitoring                                           │
│  ├─ Enhanced Monitoring (60s interval)               │
│  ├─ Performance Insights (7-day retention)           │
│  └─ CloudWatch Logs (postgresql, upgrade)            │
│                                                       │
└───────────────────────────────────────────────────────┘
```

## Usage

### Basic Example (Development)

```hcl
module "database_dev" {
  source = "./modules/database/aws"

  identifier      = "ghost-protocol-dev"
  engine_version  = "15.4"
  instance_class  = "db.t3.micro"
  database_name   = "ghostprotocol"
  master_username = "ghostadmin"
  master_password = var.db_password

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  multi_az            = false
  subnet_ids          = module.networking.private_data_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  eks_nodes_security_group_id = module.networking.eks_nodes_security_group_id

  kms_key_arn         = module.observability.kms_rds_key_arn
  monitoring_role_arn = module.observability.rds_enhanced_monitoring_role_arn

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Environment = "development"
    Project     = "ghost-protocol"
  }
}
```

### Production Example

```hcl
module "database_prod" {
  source = "./modules/database/aws"

  identifier      = "ghost-protocol-prod"
  engine_version  = "15.4"
  instance_class  = "db.r5.large"
  database_name   = "ghostprotocol"
  master_username = "ghostadmin"
  master_password = var.db_password

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_throughput    = 250

  multi_az            = true
  subnet_ids          = module.networking.private_data_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  eks_nodes_security_group_id = module.networking.eks_nodes_security_group_id

  kms_key_arn         = module.observability.kms_rds_key_arn
  monitoring_role_arn = module.observability.rds_enhanced_monitoring_role_arn

  backup_retention_period = 35
  deletion_protection     = true
  skip_final_snapshot     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 731

  create_read_replica = true
  read_replica_count  = 2
  read_replica_instance_class = "db.r5.large"
  read_replica_multi_az       = false

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
  }
}
```

### Cross-Region Disaster Recovery

```hcl
module "database_prod_dr" {
  source = "./modules/database/aws"

  identifier      = "ghost-protocol-prod"
  engine_version  = "15.4"
  instance_class  = "db.r5.large"
  database_name   = "ghostprotocol"
  master_username = "ghostadmin"
  master_password = var.db_password

  multi_az = true

  create_cross_region_replica           = true
  cross_region_replica_instance_class   = "db.r5.large"
  cross_region_replica_multi_az         = true
  cross_region_replica_backup_retention = 14
  cross_region_kms_key_arn              = var.dr_region_kms_key_arn
  cross_region_monitoring_role_arn      = var.dr_region_monitoring_role_arn

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
  }
}

provider "aws" {
  alias  = "replica_region"
  region = "us-west-2"
}
```

## Connection Guide

### Environment Variables

```bash
export DB_HOST=<db_instance_endpoint>
export DB_PORT=5432
export DB_NAME=ghostprotocol
export DB_USER=ghostadmin
export DB_PASSWORD=<master_password>
export DB_SSL_MODE=require
```

### NestJS (TypeORM)

```typescript
import { TypeOrmModule } from '@nestjs/typeorm';

TypeOrmModule.forRoot({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/rds-ca-cert.pem').toString()
  },
  synchronize: false,
  logging: true,
  entities: ['dist/**/*.entity.js']
});
```

### Prisma

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

# DATABASE_URL=postgresql://ghostadmin:password@<endpoint>:5432/ghostprotocol?sslmode=require
```

### psql (CLI)

```bash
psql "postgresql://ghostadmin:password@<endpoint>:5432/ghostprotocol?sslmode=require"

# Or with separate parameters
psql -h <endpoint> -p 5432 -U ghostadmin -d ghostprotocol
```

## Parameter Group Optimization

### Default Parameters

```hcl
parameters = [
  {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  },
  {
    name  = "log_statement"
    value = "all"
  },
  {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries > 1 second
  },
  {
    name  = "ssl"
    value = "1"
  }
]
```

### Custom Parameters for High-Traffic Production

```hcl
parameters = [
  {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  },
  {
    name  = "max_connections"
    value = "200"
  },
  {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4096}"
  },
  {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4096}"
  },
  {
    name  = "maintenance_work_mem"
    value = "2097152"  # 2GB
  },
  {
    name  = "checkpoint_completion_target"
    value = "0.9"
  },
  {
    name  = "wal_buffers"
    value = "16384"  # 16MB
  },
  {
    name  = "default_statistics_target"
    value = "100"
  },
  {
    name  = "random_page_cost"
    value = "1.1"  # SSD optimization
  },
  {
    name  = "work_mem"
    value = "20480"  # 20MB
  }
]
```

## Backup & Restore

### Manual Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier ghost-protocol-prod \
  --db-snapshot-identifier ghost-protocol-prod-manual-$(date +%Y%m%d)
```

### Restore from Snapshot

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ghost-protocol-prod-restored \
  --db-snapshot-identifier ghost-protocol-prod-snapshot-20251116 \
  --db-subnet-group-name ghost-protocol-prod-subnet-group \
  --vpc-security-group-ids sg-xxxxx
```

### Point-in-Time Recovery

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ghost-protocol-prod \
  --target-db-instance-identifier ghost-protocol-prod-pitr \
  --restore-time 2025-11-16T10:00:00Z
```

### Export to S3 (for migration)

```bash
pg_dump -h <endpoint> -U ghostadmin -d ghostprotocol \
  --format=custom --verbose --file=backup.dump

aws s3 cp backup.dump s3://ghost-protocol-backups/db/backup-$(date +%Y%m%d).dump
```

## Monitoring & Alerts

### Performance Insights Queries

```sql
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### CloudWatch Alarms (Recommended)

```hcl
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "ghost-protocol-prod-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization is too high"
  dimensions = {
    DBInstanceIdentifier = "ghost-protocol-prod"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "ghost-protocol-prod-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10737418240"  # 10GB in bytes
  alarm_description   = "RDS free storage is low"
  dimensions = {
    DBInstanceIdentifier = "ghost-protocol-prod"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "ghost-protocol-prod-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "150"
  alarm_description   = "RDS connection count is high"
  dimensions = {
    DBInstanceIdentifier = "ghost-protocol-prod"
  }
}
```

## Security Best Practices

1. **Never expose RDS publicly**: `publicly_accessible = false`
2. **Use AWS Secrets Manager**: Rotate passwords automatically
3. **Enable SSL/TLS**: `sslmode=require` in connection strings
4. **Restrict security groups**: Only allow EKS nodes
5. **Enable deletion protection**: Prevent accidental deletion
6. **Use IAM authentication**: For fine-grained access control
7. **Enable audit logging**: Monitor all queries

## Troubleshooting

### Connection Issues

```bash
# Test from EKS pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h <endpoint> -U ghostadmin -d ghostprotocol

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify parameter group
aws rds describe-db-parameters --db-parameter-group-name ghost-protocol-prod-pg
```

### Performance Issues

```sql
-- Check active queries
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC;

-- Kill long-running query
SELECT pg_terminate_backend(pid);

-- Check table bloat
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| identifier | RDS instance identifier | string | - | yes |
| engine_version | PostgreSQL version (15+) | string | "15.4" | no |
| instance_class | Instance class | string | "db.t3.micro" | no |
| master_password | Master password | string | - | yes |
| subnet_ids | DB subnet group subnets | list(string) | - | yes |
| kms_key_arn | KMS key for encryption | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_endpoint | Connection endpoint |
| db_connection_string | Full connection string |
| db_instance_arn | RDS instance ARN |

## License

MIT
