locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "secrets"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  secret_names = {
    database    = "ghost-protocol/${var.environment}/database/credentials"
    redis       = "ghost-protocol/${var.environment}/redis/password"
    openai      = "ghost-protocol/${var.environment}/api-keys/openai"
    huggingface = "ghost-protocol/${var.environment}/api-keys/huggingface"
  }
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name        = local.secret_names.database
  description = "Database credentials for Ghost Protocol ${var.environment} environment"
  kms_key_id  = var.eks_secrets_kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-database-credentials"
      Purpose     = "DatabaseCredentials"
      SecretType  = "JSON"
      Rotation    = var.enable_rotation ? "Enabled" : "Disabled"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = var.database_username
    password = "PLACEHOLDER_CHANGE_AFTER_APPLY"
    host     = var.rds_instance_endpoint != "" ? split(":", var.rds_instance_endpoint)[0] : "PLACEHOLDER_RDS_ENDPOINT"
    port     = var.rds_instance_endpoint != "" ? split(":", var.rds_instance_endpoint)[1] : "5432"
    dbname   = var.database_name
    engine   = "postgres"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "redis_password" {
  name        = local.secret_names.redis
  description = "Redis password for Ghost Protocol ${var.environment} environment"
  kms_key_id  = var.eks_secrets_kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-redis-password"
      Purpose     = "CacheCredentials"
      SecretType  = "String"
      Rotation    = "Manual"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redis_password" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = "PLACEHOLDER_CHANGE_AFTER_APPLY"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = local.secret_names.openai
  description = "OpenAI API key for Ghost Protocol ${var.environment} environment"
  kms_key_id  = var.eks_secrets_kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-openai-api-key"
      Purpose     = "ExternalAPIKey"
      SecretType  = "String"
      Rotation    = "Manual"
      Vendor      = "OpenAI"
    }
  )
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = "PLACEHOLDER_CHANGE_AFTER_APPLY"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "huggingface_api_key" {
  name        = local.secret_names.huggingface
  description = "Hugging Face API key for Ghost Protocol ${var.environment} environment"
  kms_key_id  = var.eks_secrets_kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-huggingface-api-key"
      Purpose     = "ExternalAPIKey"
      SecretType  = "String"
      Rotation    = "Manual"
      Vendor      = "HuggingFace"
    }
  )
}

resource "aws_secretsmanager_secret_version" "huggingface_api_key" {
  secret_id     = aws_secretsmanager_secret.huggingface_api_key.id
  secret_string = "PLACEHOLDER_CHANGE_AFTER_APPLY"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
