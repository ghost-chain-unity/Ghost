resource "aws_security_group_rule" "cluster_ingress_nodes_https" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.cluster_security_group_id
  source_security_group_id = var.nodes_security_group_id
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  description              = "Allow cluster control plane to communicate with worker nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = var.nodes_security_group_id
  source_security_group_id = var.cluster_security_group_id
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  description              = "Allow worker nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = var.nodes_security_group_id
  source_security_group_id = var.nodes_security_group_id
}

resource "aws_security_group_rule" "nodes_egress_all" {
  description       = "Allow worker nodes to communicate with the internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = var.nodes_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_ingress_nodes_kubelet" {
  description              = "Allow cluster control plane to communicate with worker kubelet"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = var.nodes_security_group_id
  source_security_group_id = var.cluster_security_group_id
}
