# EKS Pod Identity: runs the agent daemonset that other addons (EBS CSI
# driver, AWS Load Balancer Controller, ...) rely on to exchange their
# pod identity association for IAM credentials. No IAM role of its own.

data "aws_eks_addon_version" "this" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

resource "aws_eks_addon" "this" {
  cluster_name  = var.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = coalesce(var.addon_version, data.aws_eks_addon_version.this.version)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}
