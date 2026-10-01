module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "../modules/vpc"

  aws_region   = var.aws_region
  name         = "${var.project_name}-vpc"
  cluster_name = local.cluster_name

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway         = var.enable_nat_gateway
  single_nat_gateway         = var.single_nat_gateway
  one_nat_gateway_per_az     = var.one_nat_gateway_per_az
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint

  tags = local.tags
}
