output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "nat_gateway_ids" {
  value = module.vpc.natgw_ids
}

output "s3_gateway_endpoint_id" {
  value = module.vpc.s3_gateway_endpoint_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Run this to update your local kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "eks_pod_identity_addon_arn" {
  value = module.eks.eks_pod_identity_addon_arn
}

output "metrics_server_release_status" {
  value = module.eks.metrics_server_release_status
}

output "ebs_csi_driver_role_arn" {
  value = module.eks.ebs_csi_driver_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  value = module.eks.aws_load_balancer_controller_role_arn
}
