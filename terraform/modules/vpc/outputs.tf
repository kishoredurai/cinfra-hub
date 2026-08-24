output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "natgw_ids" {
  value = module.vpc.natgw_ids
}

output "s3_gateway_endpoint_id" {
  value = var.enable_s3_gateway_endpoint ? aws_vpc_endpoint.s3[0].id : null
}
