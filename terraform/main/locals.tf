locals {
  cluster_name = "${var.project_name}-cluster"

  # Resolve to either the VPC this stack just created or the existing one
  # the caller pointed at (see the create_vpc toggle in variables.tf).
  vpc_id             = var.create_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  private_subnet_ids = var.create_vpc ? module.vpc[0].private_subnets : var.existing_private_subnet_ids
  public_subnet_ids  = var.create_vpc ? module.vpc[0].public_subnets : var.existing_public_subnet_ids

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
