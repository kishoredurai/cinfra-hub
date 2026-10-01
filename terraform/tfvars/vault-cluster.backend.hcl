bucket       = "kishore-state" # output of bootstrap/ (state_bucket_name) — shared across clusters
key          = "clusters/vault-cluster/terraform.tfstate" # unique per cluster
region       = "us-east-1"
encrypt      = true
use_lockfile = true
