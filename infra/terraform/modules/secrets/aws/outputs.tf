output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value = {
    database    = aws_secretsmanager_secret.database_credentials.arn
    redis       = aws_secretsmanager_secret.redis_password.arn
    openai      = aws_secretsmanager_secret.openai_api_key.arn
    huggingface = aws_secretsmanager_secret.huggingface_api_key.arn
  }
}

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database_credentials.arn
}

output "database_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.database_credentials.name
}

output "redis_secret_arn" {
  description = "ARN of the Redis password secret"
  value       = aws_secretsmanager_secret.redis_password.arn
}

output "redis_secret_name" {
  description = "Name of the Redis password secret"
  value       = aws_secretsmanager_secret.redis_password.name
}

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "openai_api_key_secret_name" {
  description = "Name of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.name
}

output "huggingface_api_key_secret_arn" {
  description = "ARN of the Hugging Face API key secret"
  value       = aws_secretsmanager_secret.huggingface_api_key.arn
}

output "huggingface_api_key_secret_name" {
  description = "Name of the Hugging Face API key secret"
  value       = aws_secretsmanager_secret.huggingface_api_key.name
}

output "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda function (null if rotation disabled)"
  value       = var.enable_rotation ? aws_lambda_function.rotation[0].arn : null
}

output "rotation_lambda_name" {
  description = "Name of the rotation Lambda function (null if rotation disabled)"
  value       = var.enable_rotation ? aws_lambda_function.rotation[0].function_name : null
}

output "rotation_lambda_role_arn" {
  description = "ARN of the rotation Lambda execution role (null if rotation disabled)"
  value       = var.enable_rotation ? aws_iam_role.rotation_lambda[0].arn : null
}

output "external_secrets_operator_role_arn" {
  description = "ARN of the External Secrets Operator IAM role (null if IRSA not configured)"
  value       = local.create_irsa_role ? aws_iam_role.external_secrets_operator["enabled"].arn : null
}

output "external_secrets_operator_role_name" {
  description = "Name of the External Secrets Operator IAM role (null if IRSA not configured)"
  value       = local.create_irsa_role ? aws_iam_role.external_secrets_operator["enabled"].name : null
}

output "secret_names" {
  description = "Map of secret purpose to secret names (for SecretStore configuration)"
  value       = local.secret_names
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for secret encryption (passthrough from observability module)"
  value       = var.eks_secrets_kms_key_arn
}
