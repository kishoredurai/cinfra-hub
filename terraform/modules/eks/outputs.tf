output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.cluster.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value = module.cluster.cluster_security_group_id
}

output "oidc_provider_arn" {
  value = module.cluster.oidc_provider_arn
}

output "eks_pod_identity_addon_arn" {
  value = var.enable_eks_pod_identity ? module.eks_pod_identity[0].addon_arn : null
}

output "metrics_server_release_status" {
  value = var.enable_metrics_server ? module.metrics_server[0].helm_release_status : null
}

output "ebs_csi_driver_role_arn" {
  value = var.enable_ebs_csi_driver ? module.ebs_csi_driver[0].iam_role_arn : null
}

output "aws_load_balancer_controller_role_arn" {
  value = var.enable_aws_load_balancer_controller ? module.aws_load_balancer_controller[0].iam_role_arn : null
}
