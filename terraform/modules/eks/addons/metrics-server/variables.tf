variable "namespace" {
  description = "Namespace to install metrics-server into."
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Specific metrics-server Helm chart version to pin (e.g. \"3.12.2\"). Leave null to install the latest chart version."
  type        = string
  default     = null
}
