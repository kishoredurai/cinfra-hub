module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0" # resolves to 21.25.x — v21 renamed several inputs vs v20 (name, kubernetes_version, endpoint_*_access, addons)

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access

  enable_cluster_creator_admin_permissions = true

  # No customer-managed KMS envelope encryption for Kubernetes Secrets —
  # also skips creating the module's default KMS key. EKS/etcd still
  # encrypts data at rest regardless; this just opts out of the extra
  # customer-key layer on top of that.
  encryption_config = null

  addons = {
    # before_compute = true installs these ahead of the node groups
    # instead of depends_on-ing them. Without it, nodes come up before
    # vpc-cni exists, sit NotReady forever ("cni plugin not initialized"),
    # and the node group depends_on's these addons by default — a
    # deadlock where neither side ever finishes.
    vpc-cni    = { most_recent = true, before_compute = true }
    kube-proxy = { most_recent = true, before_compute = true }
    coredns    = { most_recent = true }
  }

  eks_managed_node_groups = {
    for name, ng in var.eks_managed_node_groups : name => {
      subnet_ids     = var.private_subnet_ids
      instance_types = ng.instance_types
      capacity_type  = ng.capacity_type
      min_size       = ng.min_size
      max_size       = ng.max_size
      desired_size   = ng.desired_size
      disk_size      = ng.disk_size
      labels         = ng.labels
    }
  }

  tags = var.tags
}

module "eks_pod_identity" {
  count  = var.enable_eks_pod_identity ? 1 : 0
  source = "./addons/eks-pod-identity"

  cluster_name       = module.cluster.cluster_name
  kubernetes_version = var.cluster_version
  addon_version      = var.eks_pod_identity_addon_version

  tags = var.tags

  depends_on = [module.cluster]
}

module "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  source = "./addons/metrics-server"

  chart_version = var.metrics_server_chart_version

  depends_on = [module.cluster]
}

module "ebs_csi_driver" {
  count  = var.enable_ebs_csi_driver ? 1 : 0
  source = "./addons/ebs-csi-driver"

  cluster_name       = module.cluster.cluster_name
  kubernetes_version = var.cluster_version
  kms_key_arns       = var.ebs_csi_driver_kms_key_arns

  tags = var.tags

  # Needs the eks-pod-identity-agent addon running to fetch IAM
  # credentials for its pod identity association, and the node
  # groups/cluster to be up.
  depends_on = [module.cluster, module.eks_pod_identity]
}

module "aws_load_balancer_controller" {
  count  = var.enable_aws_load_balancer_controller ? 1 : 0
  source = "./addons/aws-load-balancer-controller"

  cluster_name  = module.cluster.cluster_name
  vpc_id        = var.vpc_id
  aws_region    = var.aws_region
  chart_version = var.aws_load_balancer_controller_chart_version

  tags = var.tags

  depends_on = [module.cluster, module.eks_pod_identity]
}
