variable "cluster_name" {
  description = "Name of the EKS cluster to install the addon into."
  type        = string
}

variable "kubernetes_version" {
  description = "Cluster's Kubernetes version (e.g. \"1.36\"). Used to look up the most recent compatible addon build when addon_version is not set."
  type        = string
}

variable "addon_version" {
  description = "Specific aws-ebs-csi-driver addon version to pin (e.g. \"v1.48.0-eksbuild.1\"). Leave null to use the most recent version compatible with kubernetes_version."
  type        = string
  default     = null
}

variable "service_account_namespace" {
  description = "Namespace of the driver's controller service account."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the driver's controller service account (must match the chart/addon default unless overridden)."
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "kms_key_arns" {
  description = "KMS key ARNs used to encrypt EBS volumes. Grants the driver's IAM role kms:CreateGrant/Decrypt/etc on these keys. Leave empty if using the default aws/ebs key."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
