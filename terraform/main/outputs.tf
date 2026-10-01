output "vpc_id" {
  value = local.vpc_id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "nat_gateway_ids" {
  value = var.create_vpc ? module.vpc[0].natgw_ids : null
}

output "s3_gateway_endpoint_id" {
  value = var.create_vpc ? module.vpc[0].s3_gateway_endpoint_id : null
}

output "cluster_name" {
  value = var.create_eks ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  value = var.create_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_certificate_authority_data" {
  value = var.create_eks ? module.eks[0].cluster_certificate_authority_data : null
}

output "cluster_security_group_id" {
  value = var.create_eks ? module.eks[0].cluster_security_group_id : null
}

output "oidc_provider_arn" {
  value = var.create_eks ? module.eks[0].oidc_provider_arn : null
}

output "configure_kubectl" {
  description = "Run this to update your local kubeconfig."
  value       = var.create_eks ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks[0].cluster_name}" : null
}

output "eks_pod_identity_addon_arn" {
  value = var.create_eks ? module.eks[0].eks_pod_identity_addon_arn : null
}

output "metrics_server_release_status" {
  value = var.create_eks ? module.eks[0].metrics_server_release_status : null
}

output "ebs_csi_driver_role_arn" {
  value = var.create_eks ? module.eks[0].ebs_csi_driver_role_arn : null
}

output "aws_load_balancer_controller_role_arn" {
  value = var.create_eks ? module.eks[0].aws_load_balancer_controller_role_arn : null
}
