# Run against the `dev` Terraform workspace — see README.md "Running
# multiple clusters" for the exact commands.

aws_region   = "us-east-1"
project_name = "vault"
environment  = "dev"

# Create both the VPC and the cluster in this apply. Set create_eks =
# false to stand up just the VPC first, or create_vpc = false + the
# existing_* vars to attach this cluster to a VPC created elsewhere —
# see README.md "Creating the VPC and the cluster separately".
create_vpc = true
create_eks = true
# existing_vpc_id             = null
# existing_private_subnet_ids = []
# existing_public_subnet_ids  = []

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

enable_nat_gateway         = true
single_nat_gateway         = true # one shared NAT — cheaper, fine for dev
one_nat_gateway_per_az     = false
enable_s3_gateway_endpoint = true

cluster_version = "1.36"

eks_managed_node_groups = {
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 5
    desired_size   = 2
    disk_size      = 50
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
