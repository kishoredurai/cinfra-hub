variable "aws_region" {
  description = "AWS region the cluster runs in (passed through to the aws-load-balancer-controller addon)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the cluster in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs. Used for node groups and included in the cluster's control-plane ENI subnets."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs. Included in the cluster's control-plane ENI subnets."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is reachable from outside the VPC."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS API server endpoint is reachable from inside the VPC."
  type        = bool
  default     = true
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions."
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    labels         = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Add-ons
# ---------------------------------------------------------------------------

variable "enable_eks_pod_identity" {
  description = "Whether to install the eks-pod-identity-agent EKS addon. Required by enable_ebs_csi_driver and enable_aws_load_balancer_controller (and any other Pod Identity-based addon) — only turn this off if none of them are enabled."
  type        = bool
  default     = true
}

variable "eks_pod_identity_addon_version" {
  description = "Specific eks-pod-identity-agent addon version to pin. Leave null to use the most recent version compatible with cluster_version."
  type        = string
  default     = null
}

variable "enable_metrics_server" {
  description = "Whether to install metrics-server (via Helm) for kubectl top and Horizontal Pod Autoscaler support."
  type        = bool
  default     = true
}

variable "metrics_server_chart_version" {
  description = "Specific metrics-server Helm chart version to pin. Leave null to install the latest chart version."
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver" {
  description = "Whether to install the aws-ebs-csi-driver EKS addon (needed for dynamically provisioned EBS-backed PersistentVolumes)."
  type        = bool
  default     = true
}

variable "ebs_csi_driver_kms_key_arns" {
  description = "KMS key ARNs the EBS CSI driver is allowed to use for encrypted volumes. Leave empty to rely on the default aws/ebs key."
  type        = list(string)
  default     = []
}

variable "enable_aws_load_balancer_controller" {
  description = "Whether to install the AWS Load Balancer Controller (via Helm) for provisioning ALBs/NLBs from Ingress/Service objects."
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Specific aws-load-balancer-controller Helm chart version to pin. Leave null to install the latest chart version."
  type        = string
  default     = null
}
