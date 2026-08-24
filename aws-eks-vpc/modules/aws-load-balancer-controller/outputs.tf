output "iam_role_arn" {
  value = module.pod_identity.iam_role_arn
}

output "helm_release_status" {
  value = helm_release.this.status
}
