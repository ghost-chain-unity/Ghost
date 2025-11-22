resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0

  name = "${var.name_prefix}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-rds-enhanced-monitoring-role"
      Service     = "RDS"
      Purpose     = "EnhancedMonitoring"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
}

resource "aws_iam_role_policy" "rds_enhanced_monitoring_kms" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0

  name = "${var.name_prefix}-rds-enhanced-monitoring-kms-policy"
  role = aws_iam_role.rds_enhanced_monitoring[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.rds.arn,
          aws_kms_key.cloudwatch_logs.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution" {
  count = var.enable_lambda_roles ? 1 : 0

  name = "${var.name_prefix}-lambda-execution-role"

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
      Name        = "${var.name_prefix}-lambda-execution-role"
      Service     = "Lambda"
      Purpose     = "FunctionExecution"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.enable_lambda_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution[0].name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count = var.enable_lambda_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_execution[0].name
}

resource "aws_iam_role_policy" "lambda_cloudwatch" {
  count = var.enable_lambda_roles ? 1 : 0

  name = "${var.name_prefix}-lambda-cloudwatch-policy"
  role = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.cloudwatch_logs.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_xray" {
  count = var.enable_lambda_roles ? 1 : 0

  name = "${var.name_prefix}-lambda-xray-policy"
  role = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}
