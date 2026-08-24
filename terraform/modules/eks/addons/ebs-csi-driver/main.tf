# EBS CSI driver: IAM permissions via EKS Pod Identity (no OIDC/IRSA
# wiring needed) + the EKS-managed addon itself.

data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "${var.cluster_name}-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = var.kms_key_arns

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = var.service_account_namespace
      service_account = var.service_account_name
    }
  }

  tags = var.tags
}

resource "aws_eks_addon" "this" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = coalesce(var.addon_version, data.aws_eks_addon_version.this.version)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # The addon's controller pods need the pod identity association in
  # place (and the eks-pod-identity-agent addon running on the nodes)
  # to get IAM credentials.
  depends_on = [module.pod_identity]

  tags = var.tags
}
