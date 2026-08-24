module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0" # resolves to 21.25.x — v21 renamed several inputs vs v20 (name, kubernetes_version, endpoint_*_access, addons)

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access

  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true } # required by the ebs-csi-driver / aws-load-balancer-controller modules
  }

  eks_managed_node_groups = {
    for name, ng in var.eks_managed_node_groups : name => {
      subnet_ids     = module.vpc.private_subnets
      instance_types = ng.instance_types
      capacity_type  = ng.capacity_type
      min_size       = ng.min_size
      max_size       = ng.max_size
      desired_size   = ng.desired_size
      disk_size      = ng.disk_size
      labels         = ng.labels
    }
  }

  tags = local.tags
}
