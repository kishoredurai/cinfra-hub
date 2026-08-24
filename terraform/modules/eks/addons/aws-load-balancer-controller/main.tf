# AWS Load Balancer Controller: not an EKS-managed addon, so it's IAM
# permissions via EKS Pod Identity + the community Helm chart.

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "${var.cluster_name}-lb-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = var.service_account_namespace
      service_account = var.service_account_name
    }
  }

  tags = var.tags
}

resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.service_account_namespace
  version    = var.chart_version

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "region", value = var.aws_region },
    { name = "vpcId", value = var.vpc_id },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = var.service_account_name },
  ]

  # Controller pods need the pod identity association in place (and the
  # eks-pod-identity-agent addon running on the nodes) to get IAM
  # credentials for provisioning ALBs/NLBs.
  depends_on = [module.pod_identity]
}
