output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}?sslmode=require"
  sensitive   = true
}

output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.main.arn
}

output "db_option_group_id" {
  description = "ID of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.main[0].id : null
}

output "db_option_group_arn" {
  description = "ARN of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.main[0].arn : null
}

output "read_replica_endpoints" {
  description = "Endpoints of read replicas"
  value       = var.create_read_replica ? aws_db_instance.read_replica[*].endpoint : []
}

output "read_replica_ids" {
  description = "IDs of read replicas"
  value       = var.create_read_replica ? aws_db_instance.read_replica[*].id : []
}

output "cross_region_replica_endpoint" {
  description = "Endpoint of cross-region replica"
  value       = var.create_cross_region_replica ? aws_db_instance.cross_region_replica[0].endpoint : null
}

output "cross_region_replica_id" {
  description = "ID of cross-region replica"
  value       = var.create_cross_region_replica ? aws_db_instance.cross_region_replica[0].id : null
}

output "db_instance_resource_id" {
  description = "Resource ID of the RDS instance"
  value       = aws_db_instance.main.resource_id
}

output "db_instance_status" {
  description = "Status of the RDS instance"
  value       = aws_db_instance.main.status
}

output "db_instance_availability_zone" {
  description = "Availability zone of the RDS instance"
  value       = aws_db_instance.main.availability_zone
}

output "db_instance_multi_az" {
  description = "Whether the RDS instance is Multi-AZ"
  value       = aws_db_instance.main.multi_az
}

output "db_instance_hosted_zone_id" {
  description = "Hosted zone ID of the RDS instance"
  value       = aws_db_instance.main.hosted_zone_id
}
