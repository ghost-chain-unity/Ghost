data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = var.vpc_cni_service_account_role_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-vpc-cni"
    }
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  addon_version     = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-kube-proxy"
    }
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = data.aws_eks_addon_version.coredns.version
  resolve_conflicts = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-coredns"
    }
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_addon ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi_driver.version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = var.ebs_csi_service_account_role_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver"
    }
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}
