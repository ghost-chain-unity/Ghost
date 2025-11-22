data "archive_file" "rotation_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda_rotation.zip"

  source {
    content  = file("${path.module}/lambda/rotation.js")
    filename = "index.js"
  }
}

resource "aws_iam_role" "rotation_lambda" {
  count = var.enable_rotation ? 1 : 0

  name = "${var.name_prefix}-secret-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-secret-rotation-lambda-role"
      Service     = "Lambda"
      Purpose     = "SecretRotation"
    }
  )
}

resource "aws_iam_role_policy" "rotation_lambda_secrets" {
  count = var.enable_rotation ? 1 : 0

  name = "${var.name_prefix}-rotation-lambda-secrets-policy"
  role = aws_iam_role.rotation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.database_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rotation_lambda_kms" {
  count = var.enable_rotation ? 1 : 0

  name = "${var.name_prefix}-rotation-lambda-kms-policy"
  role = aws_iam_role.rotation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = var.eks_secrets_kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_vpc" {
  count = var.enable_rotation ? 1 : 0

  role       = aws_iam_role.rotation_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_basic" {
  count = var.enable_rotation ? 1 : 0

  role       = aws_iam_role.rotation_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "rotation" {
  count = var.enable_rotation ? 1 : 0

  filename         = data.archive_file.rotation_lambda.output_path
  function_name    = "${var.name_prefix}-secret-rotation"
  role             = aws_iam_role.rotation_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 300
  memory_size      = 512

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-secret-rotation"
      Service     = "Lambda"
      Purpose     = "SecretRotation"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.rotation_lambda_vpc,
    aws_iam_role_policy_attachment.rotation_lambda_basic
  ]
}

resource "aws_lambda_permission" "allow_secrets_manager" {
  count = var.enable_rotation ? 1 : 0

  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "database_credentials" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.database_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotation[0].arn

  rotation_rules {
    automatically_after_days = var.database_rotation_days
  }

  depends_on = [aws_lambda_permission.allow_secrets_manager]
}
