# Every cluster gets fully separate state: bucket, key, region, etc. all
# come from that cluster's own backend file at init time —
#   terraform init -reconfigure -backend-config=../tfvars/<cluster>.backend.hcl
# (bucket is the same shared state bucket in every cluster's file; key is
# unique per cluster, e.g. "clusters/<cluster>/terraform.tfstate" — see
# tfvars/vault-cluster.backend.hcl / tfvars/prod.backend.hcl).
#
# -reconfigure is required whenever you switch which cluster's backend
# file you're pointing at, since the target bucket/key actually changes
# (this isn't Terraform workspaces — see README "Running multiple
# clusters").
#
# use_lockfile enables S3-native state locking (Terraform >= 1.10) so no
# DynamoDB lock table is needed — the same S3 bucket handles both state
# storage and locking.
terraform {
  backend "s3" {}
}
