output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = aws_subnet.private_data[*].id
}

output "all_subnet_ids" {
  description = "All subnet IDs"
  value = concat(
    aws_subnet.public[*].id,
    aws_subnet.private_app[*].id,
    aws_subnet.private_data[*].id
  )
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_app_subnet_cidrs" {
  description = "CIDR blocks of private application subnets"
  value       = aws_subnet.private_app[*].cidr_block
}

output "private_data_subnet_cidrs" {
  description = "CIDR blocks of private data subnets"
  value       = aws_subnet.private_data[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS PostgreSQL"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = aws_security_group.redis.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb                = aws_security_group.alb.id
    eks_cluster        = aws_security_group.eks_cluster.id
    eks_nodes          = aws_security_group.eks_nodes.id
    rds                = aws_security_group.rds.id
    redis              = aws_security_group.redis.id
    vpc_endpoints      = aws_security_group.vpc_endpoints.id
  }
}

output "s3_vpc_endpoint_id" {
  description = "ID of S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "ecr_api_vpc_endpoint_id" {
  description = "ID of ECR API VPC endpoint"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "ecr_dkr_vpc_endpoint_id" {
  description = "ID of ECR DKR VPC endpoint"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "ec2_vpc_endpoint_id" {
  description = "ID of EC2 VPC endpoint"
  value       = var.enable_ec2_endpoint ? aws_vpc_endpoint.ec2[0].id : null
}

output "eks_vpc_endpoint_id" {
  description = "ID of EKS VPC endpoint"
  value       = var.enable_eks_endpoint ? aws_vpc_endpoint.eks[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.azs
}

output "public_route_table_id" {
  description = "ID of public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "IDs of private application route tables"
  value       = aws_route_table.private_app[*].id
}

output "private_data_route_table_ids" {
  description = "IDs of private data route tables"
  value       = aws_route_table.private_data[*].id
}
