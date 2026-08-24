variable "aws_region" {
  description = "AWS region (used to build the S3 gateway endpoint service name)."
  type        = string
}

variable "name" {
  description = "Name for the VPC."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster that will use this VPC. Subnets are tagged \"kubernetes.io/cluster/<cluster_name> = shared\" for k8s auto-discovery (load balancer / autoscaler controllers)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ."
  type        = list(string)
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

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
