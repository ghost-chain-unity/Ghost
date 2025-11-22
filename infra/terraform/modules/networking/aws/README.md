# AWS Networking Module

Terraform module for creating a three-tier VPC architecture with public, private application, and private data subnets across multiple availability zones.

## Features

- **Three-Tier Subnet Architecture**: Public, Private-App, and Private-Data subnets
- **Multi-AZ Deployment**: High availability across 3 availability zones
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: Per-AZ NAT gateways for private subnet egress (optional single NAT for cost savings)
- **Security Groups**: Pre-configured for ALB, EKS cluster, EKS nodes, RDS, and Redis
- **VPC Endpoints**: S3, ECR, EC2, EKS, and STS endpoints for private AWS API access
- **VPC Flow Logs**: Optional CloudWatch logging for network traffic analysis
- **Kubernetes Ready**: Subnet tags for EKS integration

## Architecture

```
┌─────────────────── VPC (10.0.0.0/16) ───────────────────┐
│                                                          │
│  ┌────────── Public Subnets (DMZ) ──────────┐          │
│  │  10.0.1.0/24 (us-east-1a)                │          │
│  │  10.0.2.0/24 (us-east-1b)                │          │
│  │  10.0.3.0/24 (us-east-1c)                │          │
│  │                                           │          │
│  │  - Internet Gateway                       │          │
│  │  - NAT Gateways                           │          │
│  │  - ALB                                    │          │
│  └───────────────────────────────────────────┘          │
│               │                                          │
│               ▼                                          │
│  ┌────── Private App Subnets ──────┐                   │
│  │  10.0.11.0/24 (us-east-1a)      │                   │
│  │  10.0.12.0/24 (us-east-1b)      │                   │
│  │  10.0.13.0/24 (us-east-1c)      │                   │
│  │                                 │                   │
│  │  - EKS Worker Nodes             │                   │
│  │  - Application Services         │                   │
│  └─────────────────────────────────┘                   │
│               │                                          │
│               ▼                                          │
│  ┌────── Private Data Subnets ──────┐                  │
│  │  10.0.21.0/24 (us-east-1a)       │                  │
│  │  10.0.22.0/24 (us-east-1b)       │                  │
│  │  10.0.23.0/24 (us-east-1c)       │                  │
│  │                                  │                  │
│  │  - RDS PostgreSQL                │                  │
│  │  - ElastiCache Redis             │                  │
│  └──────────────────────────────────┘                  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "networking" {
  source = "../../modules/networking/aws"

  name_prefix = "ghost-protocol-dev"
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Environment = "dev"
    Project     = "ghost-protocol"
  }
}
```

### Production Configuration

```hcl
module "networking" {
  source = "../../modules/networking/aws"

  name_prefix = "ghost-protocol-prod"
  vpc_cidr    = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  private_data_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_flow_logs     = true
  enable_s3_endpoint   = true
  enable_ecr_endpoint  = true
  enable_eks_endpoint  = true
  enable_ec2_endpoint  = true

  flow_logs_retention_days = 30

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
    Compliance  = "SOC2"
    Backup      = "Required"
  }
}
```

### Development Configuration (Cost Optimized)

```hcl
module "networking" {
  source = "../../modules/networking/aws"

  name_prefix = "ghost-protocol-dev"
  vpc_cidr    = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_flow_logs     = false
  enable_s3_endpoint   = true
  enable_ecr_endpoint  = false
  enable_eks_endpoint  = false
  enable_ec2_endpoint  = false

  tags = {
    Environment = "dev"
    Project     = "ghost-protocol"
  }
}
```

### Using Module Outputs

```hcl
module "networking" {
  source = "../../modules/networking/aws"
  
}

resource "aws_eks_cluster" "main" {
  name     = "ghost-protocol-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = module.networking.private_app_subnet_ids
    security_group_ids = [
      module.networking.eks_cluster_security_group_id
    ]
  }
}

resource "aws_db_instance" "main" {
  identifier = "ghost-protocol-db"
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.networking.rds_security_group_id]
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
}

resource "aws_db_subnet_group" "main" {
  name       = "ghost-protocol-db-subnet-group"
  subnet_ids = module.networking.private_data_subnet_ids

  tags = {
    Name = "ghost-protocol-db-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "ghost-protocol-redis"
  
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [module.networking.redis_security_group_id]
  
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 3
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "ghost-protocol-redis-subnet-group"
  subnet_ids = module.networking.private_data_subnet_ids
}

resource "aws_lb" "main" {
  name               = "ghost-protocol-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.networking.alb_security_group_id]
  subnets            = module.networking.public_subnet_ids

  tags = {
    Name = "ghost-protocol-alb"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| azs | Availability zones for subnet deployment | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| private_app_subnet_cidrs | CIDR blocks for private application subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | no |
| private_data_subnet_cidrs | CIDR blocks for private data subnets | `list(string)` | `["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnet egress | `bool` | `true` | no |
| single_nat_gateway | Use a single NAT Gateway for all AZs (cost optimization) | `bool` | `false` | no |
| enable_dns_hostnames | Enable DNS hostnames in VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in VPC | `bool` | `true` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_logs_retention_days | Retention period for VPC Flow Logs in CloudWatch | `number` | `7` | no |
| enable_s3_endpoint | Enable S3 VPC endpoint | `bool` | `true` | no |
| enable_ecr_endpoint | Enable ECR VPC endpoints | `bool` | `true` | no |
| enable_eks_endpoint | Enable EKS VPC endpoint | `bool` | `true` | no |
| enable_ec2_endpoint | Enable EC2 VPC endpoints | `bool` | `true` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | IDs of public subnets |
| private_app_subnet_ids | IDs of private application subnets |
| private_data_subnet_ids | IDs of private data subnets |
| all_subnet_ids | All subnet IDs |
| internet_gateway_id | ID of the Internet Gateway |
| nat_gateway_ids | IDs of NAT Gateways |
| nat_gateway_public_ips | Public IPs of NAT Gateways |
| alb_security_group_id | Security group ID for Application Load Balancer |
| eks_cluster_security_group_id | Security group ID for EKS cluster control plane |
| eks_nodes_security_group_id | Security group ID for EKS worker nodes |
| rds_security_group_id | Security group ID for RDS PostgreSQL |
| redis_security_group_id | Security group ID for ElastiCache Redis |
| vpc_endpoints_security_group_id | Security group ID for VPC endpoints |
| security_group_ids | Map of all security group IDs |
| availability_zones | List of availability zones used |

## Security Groups

The module creates the following security groups:

### ALB Security Group
- **Ingress**: HTTPS (443), HTTP (80) from 0.0.0.0/0
- **Egress**: All traffic
- **Use Case**: Application Load Balancer

### EKS Cluster Security Group
- **Ingress**: HTTPS (443) from EKS worker nodes
- **Egress**: All traffic
- **Use Case**: EKS control plane

### EKS Nodes Security Group
- **Ingress**: 
  - All traffic from ALB security group
  - All traffic from itself (inter-node communication)
  - HTTPS (443) from EKS cluster security group
- **Egress**: All traffic
- **Use Case**: EKS worker nodes
- **Tags**: Includes kubernetes.io tags for EKS integration

### RDS Security Group
- **Ingress**: PostgreSQL (5432) from EKS nodes security group
- **Egress**: All traffic
- **Use Case**: RDS PostgreSQL database

### Redis Security Group
- **Ingress**: Redis (6379) from EKS nodes security group
- **Egress**: All traffic
- **Use Case**: ElastiCache Redis

### VPC Endpoints Security Group
- **Ingress**: HTTPS (443) from VPC CIDR
- **Egress**: All traffic
- **Use Case**: VPC interface endpoints

## VPC Endpoints

The module creates the following VPC endpoints:

- **S3** (Gateway): Cost-effective S3 access without NAT Gateway charges
- **ECR API** (Interface): Pull container images from ECR
- **ECR DKR** (Interface): Docker registry operations
- **EC2** (Interface): EC2 API access
- **EKS** (Interface): EKS API access
- **STS** (Interface): AWS Security Token Service
- **CloudWatch Logs** (Interface): Log delivery (when flow logs enabled)

## Cost Considerations

### Development Environment
- Use `single_nat_gateway = true` to reduce NAT Gateway costs (saves ~$64/month)
- Disable unnecessary VPC endpoints
- Disable flow logs if not needed

### Production Environment
- Use one NAT Gateway per AZ for high availability
- Enable all VPC endpoints to reduce data transfer costs
- Enable flow logs for security monitoring

### Cost Breakdown (Production)
- **NAT Gateways**: 3 x $32/month = $96/month
- **VPC Endpoints (Interface)**: 6 x $7.2/month = ~$43/month
- **VPC Endpoints (Gateway)**: Free (S3)
- **Data Transfer**: Variable based on usage
- **Total Base Cost**: ~$139/month + data transfer

## Best Practices

1. **Multi-AZ Deployment**: Always use 3 availability zones for production
2. **Private Subnets**: Deploy application workloads in private subnets
3. **Data Isolation**: Keep databases in dedicated private-data subnets
4. **Security Groups**: Use security groups for defense in depth
5. **VPC Endpoints**: Enable endpoints to reduce data transfer costs and improve security
6. **Flow Logs**: Enable in production for security monitoring and troubleshooting
7. **NAT Gateways**: Use one per AZ in production for high availability

## Examples

See the `examples/` directory for complete working examples:
- `examples/dev/` - Development configuration
- `examples/staging/` - Staging configuration
- `examples/prod/` - Production configuration

## License

MIT

## Authors

Ghost Protocol DevOps Team

## Changelog

### Version 1.0.0
- Initial release
- Three-tier subnet architecture
- Multi-AZ support
- Security groups for ALB, EKS, RDS, Redis
- VPC endpoints for S3, ECR, EC2, EKS
- VPC Flow Logs support
