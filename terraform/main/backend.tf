# Intentionally left partial. Supply the real values at init time with:
#   terraform init -backend-config=backend.hcl
# (copy backend.hcl.example -> backend.hcl and fill it in; backend.hcl is gitignored)
#
# use_lockfile enables S3-native state locking (Terraform >= 1.10) so no
# DynamoDB lock table is needed — the same S3 bucket handles both state
# storage and locking.
terraform {
  backend "s3" {}
}
