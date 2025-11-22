resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private_app[*].id,
    aws_route_table.private_data[*].id
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ecr-api-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ecr-dkr-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_ec2_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ec2-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "eks" {
  count = var.enable_eks_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-logs-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_eks_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sts-endpoint"
    }
  )
}

data "aws_region" "current" {}
