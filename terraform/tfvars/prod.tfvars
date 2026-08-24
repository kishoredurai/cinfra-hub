# Run against the `prod` Terraform workspace — see README.md "Running
# multiple clusters" for the exact commands.
#
# Uses a distinct vpc_cidr from dev.tfvars — not required (each workspace
# gets its own VPC either way), just good hygiene in case they're ever
# peered or connected to a shared Transit Gateway.

aws_region   = "us-east-1"
project_name = "prod"
environment  = "prod"

vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

enable_nat_gateway         = true
single_nat_gateway         = false
one_nat_gateway_per_az     = true # one NAT per AZ — resilient, worth the extra cost in prod
enable_s3_gateway_endpoint = true

cluster_version = "1.36"

eks_managed_node_groups = {
  default = {
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 6
    desired_size   = 3
    disk_size      = 100
    labels         = {}
  }
}

enable_eks_pod_identity        = true # required by ebs-csi-driver / aws-load-balancer-controller below
eks_pod_identity_addon_version = null # null = latest
enable_metrics_server          = true
metrics_server_chart_version   = null # null = latest

enable_ebs_csi_driver                      = true
ebs_csi_driver_kms_key_arns                = []
enable_aws_load_balancer_controller        = true
aws_load_balancer_controller_chart_version = null # null = latest
