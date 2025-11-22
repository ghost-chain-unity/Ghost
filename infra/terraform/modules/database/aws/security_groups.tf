resource "aws_security_group_rule" "rds_ingress_eks_nodes" {
  count = var.create_security_group_rules ? 1 : 0

  description              = "Allow EKS nodes to access RDS PostgreSQL"
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = var.eks_nodes_security_group_id
}

resource "aws_security_group_rule" "rds_ingress_additional" {
  for_each = var.create_security_group_rules ? var.additional_ingress_rules : {}

  description              = each.value.description
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
}
