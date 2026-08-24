module "ebs_csi_driver" {
  count  = var.enable_ebs_csi_driver ? 1 : 0
  source = "../modules/ebs-csi-driver"

  cluster_name       = module.eks.cluster_name
  kubernetes_version = var.cluster_version
  kms_key_arns       = var.ebs_csi_driver_kms_key_arns

  tags = local.tags

  # cluster_name is available before the node groups / eks-pod-identity-agent
  # addon are done, so force this to wait on the whole eks module rather
  # than just that one output.
  depends_on = [module.eks]
}

module "aws_load_balancer_controller" {
  count  = var.enable_aws_load_balancer_controller ? 1 : 0
  source = "../modules/aws-load-balancer-controller"

  cluster_name  = module.eks.cluster_name
  vpc_id        = module.vpc.vpc_id
  aws_region    = var.aws_region
  chart_version = var.aws_load_balancer_controller_chart_version

  tags = local.tags

  depends_on = [module.eks]
}
