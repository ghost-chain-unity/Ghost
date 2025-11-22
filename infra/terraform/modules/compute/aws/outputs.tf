output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = var.enable_irsa ? aws_iam_openidconnect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = var.enable_irsa ? aws_eks_cluster.main.identity[0].oidc[0].issuer : null
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer (without https://)"
  value       = try(replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", ""), "")
}

output "node_group_ids" {
  description = "IDs of all node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

output "node_group_arns" {
  description = "ARNs of all node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.arn }
}

output "node_group_statuses" {
  description = "Status of all node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by node groups"
  value       = var.node_role_arn
}

output "general_node_group_id" {
  description = "ID of the general node group"
  value       = var.enable_node_groups ? aws_eks_node_group.main["general"].id : null
}

output "compute_node_group_id" {
  description = "ID of the compute-optimized node group"
  value       = var.enable_node_groups ? aws_eks_node_group.main["compute_optimized"].id : null
}

output "memory_node_group_id" {
  description = "ID of the memory-optimized node group"
  value       = var.enable_node_groups ? aws_eks_node_group.main["memory_optimized"].id : null
}

output "vpc_cni_addon_version" {
  description = "Version of VPC CNI addon"
  value       = var.enable_vpc_cni_addon ? aws_eks_addon.vpc_cni[0].addon_version : null
}

output "kube_proxy_addon_version" {
  description = "Version of kube-proxy addon"
  value       = var.enable_kube_proxy_addon ? aws_eks_addon.kube_proxy[0].addon_version : null
}

output "coredns_addon_version" {
  description = "Version of CoreDNS addon"
  value       = var.enable_coredns_addon ? aws_eks_addon.coredns[0].addon_version : null
}

output "ebs_csi_addon_version" {
  description = "Version of EBS CSI driver addon"
  value       = var.enable_ebs_csi_addon ? aws_eks_addon.ebs_csi_driver[0].addon_version : null
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}
