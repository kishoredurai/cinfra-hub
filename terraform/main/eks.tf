module "eks" {
  count  = var.create_eks ? 1 : 0
  source = "../modules/eks"

  aws_region      = var.aws_region
  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access

  eks_managed_node_groups = var.eks_managed_node_groups

  enable_eks_pod_identity        = var.enable_eks_pod_identity
  eks_pod_identity_addon_version = var.eks_pod_identity_addon_version

  enable_metrics_server        = var.enable_metrics_server
  metrics_server_chart_version = var.metrics_server_chart_version

  enable_ebs_csi_driver       = var.enable_ebs_csi_driver
  ebs_csi_driver_kms_key_arns = var.ebs_csi_driver_kms_key_arns

  enable_aws_load_balancer_controller        = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller_chart_version = var.aws_load_balancer_controller_chart_version

  tags = local.tags
}
