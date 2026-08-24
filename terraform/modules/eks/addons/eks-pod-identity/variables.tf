variable "cluster_name" {
  description = "Name of the EKS cluster to install the addon into."
  type        = string
}

variable "kubernetes_version" {
  description = "Cluster's Kubernetes version (e.g. \"1.36\"). Used to look up the most recent compatible addon build when addon_version is not set."
  type        = string
}

variable "addon_version" {
  description = "Specific eks-pod-identity-agent addon version to pin (e.g. \"v1.3.7-eksbuild.2\"). Leave null to use the most recent version compatible with kubernetes_version."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
