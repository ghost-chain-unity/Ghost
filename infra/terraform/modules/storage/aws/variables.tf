variable "project_name" {
  description = "Project name for naming resources"
  type        = string
  default     = "ghost-protocol"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for the S3 buckets"
  type        = string
  default     = "us-east-1"
}

variable "kms_key_arn" {
  description = "ARN of KMS key for S3 encryption (from observability module)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Block all public access to S3 buckets"
  type        = bool
  default     = true
}

variable "enable_access_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering"
  type        = bool
  default     = false
}

variable "app_data_lifecycle_rules" {
  description = "Lifecycle rules for application data bucket"
  type = list(object({
    id          = string
    enabled     = bool
    prefix      = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days             = optional(number)
    noncurrent_transitions      = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_expiration_days = optional(number)
  }))
  default = [
    {
      id      = "transition-old-versions"
      enabled = true
      noncurrent_transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      noncurrent_expiration_days = 365
    }
  ]
}

variable "backup_lifecycle_rules" {
  description = "Lifecycle rules for backup bucket"
  type = list(object({
    id          = string
    enabled     = bool
    prefix      = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days             = optional(number)
    noncurrent_transitions      = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_expiration_days = optional(number)
  }))
  default = [
    {
      id      = "transition-to-glacier"
      enabled = true
      transitions = [
        {
          days          = 30
          storage_class = "GLACIER"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration_days = 365
    }
  ]
}

variable "logs_lifecycle_rules" {
  description = "Lifecycle rules for logs bucket"
  type = list(object({
    id          = string
    enabled     = bool
    prefix      = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days             = optional(number)
    noncurrent_transitions      = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_expiration_days = optional(number)
  }))
  default = [
    {
      id      = "expire-old-logs"
      enabled = true
      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      expiration_days = 365
    }
  ]
}

variable "static_assets_lifecycle_rules" {
  description = "Lifecycle rules for static assets bucket"
  type = list(object({
    id          = string
    enabled     = bool
    prefix      = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days             = optional(number)
    noncurrent_transitions      = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_expiration_days = optional(number)
  }))
  default = []
}

variable "enable_backup_object_lock" {
  description = "Enable Object Lock for backup bucket (WORM)"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Object Lock mode (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "Object Lock mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "object_lock_retention_days" {
  description = "Object Lock retention period in days"
  type        = number
  default     = 365
}

variable "allowed_role_arns" {
  description = "List of IAM role ARNs allowed to access S3 buckets"
  type        = list(string)
  default     = []
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "enable_backup_replication" {
  description = "Enable replication for backup bucket"
  type        = bool
  default     = true
}

variable "enable_logs_replication" {
  description = "Enable replication for logs bucket"
  type        = bool
  default     = true
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = "us-west-2"
}

variable "replication_destination_bucket_arn_prefix" {
  description = "ARN prefix for destination buckets (e.g., arn:aws:s3:::)"
  type        = string
  default     = "arn:aws:s3:::"
}

variable "replication_destination_kms_key_arn" {
  description = "KMS key ARN in destination region for replication"
  type        = string
  default     = null
}

variable "replication_storage_class" {
  description = "Storage class for replicated objects"
  type        = string
  default     = "STANDARD_IA"

  validation {
    condition     = contains(["STANDARD", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE"], var.replication_storage_class)
    error_message = "Invalid storage class for replication."
  }
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for static assets"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Invalid CloudFront price class."
  }
}

variable "cloudfront_aliases" {
  description = "Alternate domain names (CNAMEs) for CloudFront"
  type        = list(string)
  default     = []
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be in us-east-1)"
  type        = string
  default     = null
}

variable "cloudfront_default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "cloudfront_min_ttl" {
  description = "Minimum TTL for CloudFront cache"
  type        = number
  default     = 0
}

variable "cloudfront_default_ttl" {
  description = "Default TTL for CloudFront cache"
  type        = number
  default     = 86400
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL for CloudFront cache"
  type        = number
  default     = 31536000
}

variable "cloudfront_forward_headers" {
  description = "Headers to forward to origin"
  type        = list(string)
  default     = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
}

variable "cloudfront_custom_cache_behaviors" {
  description = "Custom cache behaviors for CloudFront"
  type = list(object({
    path_pattern          = string
    allowed_methods       = list(string)
    cached_methods        = list(string)
    forward_query_string  = bool
    forward_headers       = optional(list(string), [])
    forward_cookies       = optional(string, "none")
    min_ttl               = optional(number, 0)
    default_ttl           = optional(number, 86400)
    max_ttl               = optional(number, 31536000)
    compress              = optional(bool, true)
  }))
  default = []
}

variable "cloudfront_geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.cloudfront_geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist."
  }
}

variable "cloudfront_geo_restriction_locations" {
  description = "Country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "cloudfront_minimum_protocol_version" {
  description = "Minimum TLS protocol version for CloudFront"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cloudfront_custom_error_response_path" {
  description = "Custom error response path (for SPA routing)"
  type        = string
  default     = "/index.html"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
