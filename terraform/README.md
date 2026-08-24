# terraform

Terraform for a VPC (public + private subnets, internet gateway, optional
NAT gateway(s), optional S3 gateway endpoint) and an EKS cluster with a
managed node group, plus four add-ons built on top of it: EKS Pod Identity,
the EBS CSI driver, the AWS Load Balancer Controller, and Metrics Server.

```
terraform/
├── bootstrap/            # one-time: creates the S3 state bucket (local state)
├── main/                 # root module — wires vpc + eks together, owns the backend
├── clusters/             # per-cluster *.tfvars (dev.tfvars, prod.tfvars, ...)
└── modules/
    ├── vpc/               # VPC, subnets, IGW, NAT gateway(s), S3 gateway endpoint
    └── eks/               # EKS cluster + managed node groups
        └── addons/
            ├── eks-pod-identity/             # eks-pod-identity-agent EKS addon
            ├── ebs-csi-driver/                # aws-ebs-csi-driver EKS addon
            ├── aws-load-balancer-controller/  # AWS Load Balancer Controller (Helm)
            └── metrics-server/                # Metrics Server (Helm)
```

- `bootstrap/` — one-time root module that creates the S3 bucket used to
  store remote state for `main/`. Uses **local** state itself (chicken-and-egg:
  the bucket has to exist before anything can use it as a backend).
- `main/` — the root module: `versions.tf`/`provider.tf`/`backend.tf`
  (setup), `variables.tf` (every input, declarations only — no values),
  `vpc.tf`/`eks.tf` (the actual module calls), `outputs.tf`. Calls
  `modules/vpc` and `modules/eks` and wires the VPC's outputs into the EKS
  module's inputs. State is stored in S3, and locking uses Terraform's
  native S3 lockfile (`use_lockfile = true`, Terraform >= 1.10) — no
  DynamoDB table required.
- `clusters/` — one `*.tfvars` file per cluster you want to stand up
  (`dev.tfvars`, `prod.tfvars`, ...). `main/` has no values of its own
  baked in; every cluster is `main/` + one of these files + one Terraform
  workspace. See "Running multiple clusters" below.
- `modules/vpc/` — standalone VPC module (usable outside this repo).
- `modules/eks/` — standalone EKS module (usable outside this repo): creates
  the cluster + node groups, and owns four add-ons as nested submodules
  under `modules/eks/addons/`, each gated by its own `enable_*` toggle.
  - `modules/eks/addons/eks-pod-identity/` — installs the
    `eks-pod-identity-agent` EKS addon. This is the credential-delivery
    mechanism the other two IAM-needing add-ons below depend on; leave it
    enabled unless neither of them is.
  - `modules/eks/addons/ebs-csi-driver/` — installs the `aws-ebs-csi-driver`
    EKS addon, with IAM permissions granted via EKS Pod Identity.
  - `modules/eks/addons/aws-load-balancer-controller/` — installs the AWS
    Load Balancer Controller via its Helm chart, also via EKS Pod Identity.
  - `modules/eks/addons/metrics-server/` — installs Metrics Server via its
    Helm chart (no AWS API calls, no IAM/Pod Identity needed).

Versions pinned as of 2026-08-24 (verify current values before applying to
prod — Terraform and EKS both ship new releases regularly):
- Terraform >= 1.15.0 (latest stable: 1.15.8)
- AWS provider ~> 6.57, kubernetes provider ~> 2.38, helm provider ~> 3.0
- `terraform-aws-modules/vpc/aws` ~> 6.6
- `terraform-aws-modules/eks/aws` ~> 21.0
- `terraform-aws-modules/eks-pod-identity/aws` ~> 1.0
- EKS cluster version default: 1.36 (newest generally available)

## Usage

### 1. Create the state bucket (once per account/environment)

```bash
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=<globally-unique-bucket-name>" -var="aws_region=us-east-1"
```

Note the `state_bucket_name` output.

### 2. Point main/ at that bucket

```bash
cd ../main
cp backend.hcl.example backend.hcl
# edit backend.hcl: set bucket = "<name from step 1>", region, key
terraform init -backend-config=backend.hcl
```

### 3. Pick (or create) a cluster's workspace, then plan/apply it

Each cluster is a Terraform **workspace** + a **`.tfvars` file** in
`clusters/`. `clusters/dev.tfvars` and `clusters/prod.tfvars` are ready to
use as-is (they use distinct `project_name`/`vpc_cidr` so they never
collide if run in the same account); copy one to add another cluster.

```bash
terraform workspace new dev      # first time only — creates + switches to it
terraform plan  -var-file=../clusters/dev.tfvars
terraform apply -var-file=../clusters/dev.tfvars
```

### 4. Connect kubectl

```bash
$(terraform output -raw configure_kubectl)
```

## Running multiple clusters

`main/` carries no cluster-specific values — every cluster is just
"`main/` + a `clusters/<name>.tfvars` file + a same-named Terraform
workspace". Workspaces keep each cluster's state separate within the
*same* S3 bucket/backend (the object key becomes `env:/<workspace>/<key>`
automatically), so `terraform init` only ever needs to run once, even
across many clusters.

```bash
cd main
terraform init -backend-config=backend.hcl   # once, regardless of cluster count

# stand up dev
terraform workspace new dev
terraform apply -var-file=../clusters/dev.tfvars

# stand up prod, without touching dev's state
terraform workspace new prod
terraform apply -var-file=../clusters/prod.tfvars

# see what exists / move between them
terraform workspace list
terraform workspace select dev
terraform plan -var-file=../clusters/dev.tfvars   # confirms no drift

# add a third cluster
cp ../clusters/dev.tfvars ../clusters/staging.tfvars
# edit staging.tfvars: at minimum project_name and vpc_cidr must be unique
terraform workspace new staging
terraform apply -var-file=../clusters/staging.tfvars
```

Whichever workspace is currently selected is the one `terraform plan` /
`apply` / `destroy` / `output` act on — always run `terraform workspace
show` first if you're not sure which cluster you're about to change.

## Toggles worth knowing about

- `enable_nat_gateway` — turn off entirely for a fully private/air-gapped
  design (nothing in private subnets gets outbound internet).
- `single_nat_gateway` vs `one_nat_gateway_per_az` — cost (1 NAT) vs
  resilience (1 NAT per AZ). Ignored if `enable_nat_gateway = false`.
- `enable_s3_gateway_endpoint` — routes S3 traffic (ECR pulls, app data)
  over the AWS backbone instead of through the NAT gateway; free, no
  reason to disable it unless you have a conflicting endpoint already.
- `eks_managed_node_groups` — map, so you can define multiple node groups
  (e.g. a spot pool and an on-demand pool) by adding more keys.
- `enable_ebs_csi_driver` / `enable_aws_load_balancer_controller` /
  `enable_metrics_server` — turn any add-on off if you don't need it (e.g.
  no EBS-backed PVCs, or you're running your own ingress).
- `enable_eks_pod_identity` — only turn this off if you've also disabled
  both `enable_ebs_csi_driver` and `enable_aws_load_balancer_controller`;
  otherwise those add-ons' pods have no way to get IAM credentials.

## Destroy order

```bash
cd main
terraform workspace select dev                              # pick the cluster
terraform destroy -var-file=../clusters/dev.tfvars

cd ../bootstrap && terraform destroy   # only if you're tearing down the state bucket too
```
