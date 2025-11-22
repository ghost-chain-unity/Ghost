output "bucket_ids" {
  description = "Map of bucket types to bucket IDs"
  value       = { for k, v in aws_s3_bucket.main : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket types to bucket ARNs"
  value       = { for k, v in aws_s3_bucket.main : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of bucket types to bucket domain names"
  value       = { for k, v in aws_s3_bucket.main : k => v.bucket_domain_name }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket types to bucket regional domain names"
  value       = { for k, v in aws_s3_bucket.main : k => v.bucket_regional_domain_name }
}

output "app_data_bucket_id" {
  description = "ID of the application data bucket"
  value       = aws_s3_bucket.main["application"].id
}

output "app_data_bucket_arn" {
  description = "ARN of the application data bucket"
  value       = aws_s3_bucket.main["application"].arn
}

output "backup_bucket_id" {
  description = "ID of the backup bucket"
  value       = aws_s3_bucket.main["backup"].id
}

output "backup_bucket_arn" {
  description = "ARN of the backup bucket"
  value       = aws_s3_bucket.main["backup"].arn
}

output "logs_bucket_id" {
  description = "ID of the logs bucket"
  value       = aws_s3_bucket.main["logs"].id
}

output "logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = aws_s3_bucket.main["logs"].arn
}

output "static_assets_bucket_id" {
  description = "ID of the static assets bucket"
  value       = aws_s3_bucket.main["static"].id
}

output "static_assets_bucket_arn" {
  description = "ARN of the static assets bucket"
  value       = aws_s3_bucket.main["static"].arn
}

output "replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = var.enable_cross_region_replication ? aws_iam_role.replication[0].arn : null
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].id : null
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].arn : null
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : null
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].hosted_zone_id : null
}

output "cloudfront_oai_iam_arn" {
  description = "IAM ARN of the CloudFront Origin Access Identity"
  value       = var.enable_cloudfront ? aws_cloudfront_origin_access_identity.main[0].iam_arn : null
}

output "all_bucket_details" {
  description = "Comprehensive map of all bucket details"
  value = {
    for k, v in aws_s3_bucket.main : k => {
      id                      = v.id
      arn                     = v.arn
      domain_name             = v.bucket_domain_name
      regional_domain_name    = v.bucket_regional_domain_name
      versioning_enabled      = var.enable_versioning
      encryption_enabled      = true
      public_access_blocked   = var.block_public_access
    }
  }
}
