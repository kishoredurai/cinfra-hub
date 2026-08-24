output "addon_arn" {
  value = aws_eks_addon.this.arn
}

output "addon_version" {
  value = aws_eks_addon.this.addon_version
}

output "iam_role_arn" {
  value = module.pod_identity.iam_role_arn
}
