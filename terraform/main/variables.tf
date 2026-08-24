variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resources (VPC, cluster, tags)."
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment tag (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway(s) so private subnets get outbound internet access."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, use a single shared NAT gateway for all private subnets (cheaper, less resilient). Ignored if enable_nat_gateway is false."
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "If true, create one NAT gateway per AZ (most resilient, most expensive). Overrides single_nat_gateway when true."
  type        = bool
  default     = false
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create an S3 gateway VPC endpoint so traffic to S3 (e.g. ECR image layers, app data) stays on the AWS network instead of routing through the NAT gateway."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster. Check `aws eks describe-addon-versions` / the EKS release calendar for the current newest supported version."
  type        = string
  default     = "1.36"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is reachable from outside the VPC."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
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
  default = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
      labels         = {}
    }
  }
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
