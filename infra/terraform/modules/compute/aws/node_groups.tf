locals {
  node_groups = {
    general = {
      name            = "general"
      instance_types  = var.general_node_group_instance_types
      capacity_type   = var.general_node_group_capacity_type
      min_size        = var.general_node_group_min_size
      max_size        = var.general_node_group_max_size
      desired_size    = var.general_node_group_desired_size
      disk_size       = var.general_node_group_disk_size
      labels = {
        workload = "general"
        tier     = "application"
      }
      taints = []
    }
    compute_optimized = {
      name            = "compute-optimized"
      instance_types  = var.compute_node_group_instance_types
      capacity_type   = var.compute_node_group_capacity_type
      min_size        = var.compute_node_group_min_size
      max_size        = var.compute_node_group_max_size
      desired_size    = var.compute_node_group_desired_size
      disk_size       = var.compute_node_group_disk_size
      labels = {
        workload = "compute-intensive"
        tier     = "blockchain"
      }
      taints = var.compute_node_group_taints
    }
    memory_optimized = {
      name            = "memory-optimized"
      instance_types  = var.memory_node_group_instance_types
      capacity_type   = var.memory_node_group_capacity_type
      min_size        = var.memory_node_group_min_size
      max_size        = var.memory_node_group_max_size
      desired_size    = var.memory_node_group_desired_size
      disk_size       = var.memory_node_group_disk_size
      labels = {
        workload = "memory-intensive"
        tier     = "data"
      }
      taints = var.memory_node_group_taints
    }
  }
}

resource "aws_launch_template" "node_group" {
  for_each = local.node_groups

  name_prefix = "${var.cluster_name}-${each.value.name}-"
  description = "Launch template for ${each.value.name} node group"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    cluster_ca          = aws_eks_cluster.main.certificate_authority[0].data
    bootstrap_arguments = var.bootstrap_extra_args
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name      = "${var.cluster_name}-${each.value.name}-node"
        NodeGroup = each.value.name
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name      = "${var.cluster_name}-${each.value.name}-volume"
        NodeGroup = each.value.name
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.value.name}-lt"
    }
  )
}

resource "aws_eks_node_group" "main" {
  for_each = var.enable_node_groups ? local.node_groups : {}

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.value.name}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  version         = var.node_group_version != null ? var.node_group_version : var.cluster_version

  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = "$Latest"
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.cluster_name}-${each.value.name}"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"         = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}
