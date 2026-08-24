variable "cluster_name" {
  description = "Name of the EKS cluster to install the controller into."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the cluster runs in (passed to the chart so it doesn't have to auto-detect it)."
  type        = string
}

variable "aws_region" {
  description = "AWS region the cluster runs in (passed to the chart so it doesn't have to auto-detect it)."
  type        = string
}

variable "chart_version" {
  description = "Specific aws-load-balancer-controller Helm chart version to pin (e.g. \"1.11.0\"). Leave null to install the latest chart version."
  type        = string
  default     = null
}

variable "service_account_namespace" {
  description = "Namespace to install the controller and its service account into."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the controller's service account."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  description = "Tags applied to created IAM resources."
  type        = map(string)
  default     = {}
}
