output "addon_arn" {
  value = aws_eks_addon.this.arn
}

output "addon_version" {
  value = aws_eks_addon.this.addon_version
}
