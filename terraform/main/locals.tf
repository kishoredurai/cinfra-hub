locals {
  cluster_name = "${var.project_name}-cluster"

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
