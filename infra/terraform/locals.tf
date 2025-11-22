locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
      ManagedBy   = "Terraform"
      Repository  = "ghost-protocol"
    },
    var.tags
  )

  name_prefix = "${var.project_name}-${var.environment}"

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  private_app_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]

  private_data_subnets = [
    "10.0.21.0/24",
    "10.0.22.0/24",
    "10.0.23.0/24"
  ]

  azs = var.availability_zones
}
