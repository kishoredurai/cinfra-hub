provider "aws" {
  region = var.aws_region

  # This account auto-tags every new resource (Owner, c7n-created-*) via
  # an org-wide automation the moment it's created, and an SCP blocks
  # anyone — including this role — from removing those tags. Since our
  # `tags` values don't include them, Terraform would otherwise try to
  # reconcile them away on every apply and get an AccessDenied. Ignoring
  # them here means Terraform never attempts to touch them, on any
  # resource.
  ignore_tags {
    keys         = ["Owner"]
    key_prefixes = ["c7n-"]
  }
}

# kubernetes/helm auth against the cluster this stack just created, via
# short-lived tokens fetched on demand (no long-lived kubeconfig needed).
# try(...) covers create_eks = false — the values are never actually used
# by anything in that case since the add-on submodules also have count 0,
# but the provider blocks still get evaluated on every plan/apply.
provider "kubernetes" {
  host                   = try(module.eks[0].cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(module.eks[0].cluster_name, ""), "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = try(module.eks[0].cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), "")

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks[0].cluster_name, ""), "--region", var.aws_region]
    }
  }
}
