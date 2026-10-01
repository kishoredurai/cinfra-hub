# terraform

Terraform for a VPC (public + private subnets, internet gateway, optional
NAT gateway(s), optional S3 gateway endpoint) and an EKS cluster with a
managed node group, plus four add-ons built on top of it: EKS Pod Identity,
the EBS CSI driver, the AWS Load Balancer Controller, and Metrics Server.

```
terraform/
├── bootstrap/            # one-time: creates the S3 state bucket (local state)
├── main/                 # root module — wires vpc + eks together, owns the backend
├── tfvars/               # per cluster: <name>.tfvars + <name>.backend.hcl
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
- `tfvars/` — two files per cluster you want to stand up:
  `<name>.tfvars` (its input variables — `project_name`, CIDRs, node group
  sizing, add-on toggles, ...) and `<name>.backend.hcl` (where *that
  cluster's* state lives: same shared bucket, but a **unique `key`** —
  `clusters/<name>/terraform.tfstate` — so every cluster's state is fully
  separate, not just namespaced within a shared one). `main/` has no
  values of its own baked in; every cluster is `main/` + this pair of
  files. See "Running multiple clusters" below.
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
terraform apply   # defaults to state_bucket_name = "kishore-state" in us-east-1
# or override: terraform apply -var="state_bucket_name=<your-bucket-name>" -var="aws_region=<region>"
```

Note the `state_bucket_name` output.

### 2. Point main/ at a cluster's state

Every cluster in `tfvars/` has its own `<name>.backend.hcl` (bucket +
unique `key`) — `tfvars/vault-cluster.backend.hcl` and
`tfvars/prod.backend.hcl` already default to `bucket = "kishore-state"`
in `us-east-1`; edit them if you used a different name/region in step 1.

```bash
cd ../main
terraform init -backend-config=../tfvars/vault-cluster.backend.hcl
```

### 3. Plan/apply that cluster

```bash
terraform plan  -var-file=../tfvars/vault-cluster.tfvars
terraform apply -var-file=../tfvars/vault-cluster.tfvars
```

### 4. Connect kubectl

```bash
$(terraform output -raw configure_kubectl)
```

## Running multiple clusters

`main/` carries no cluster-specific values, and no cluster-specific
backend target either — every cluster is just "`main/` + a
`tfvars/<name>.tfvars` file + a `tfvars/<name>.backend.hcl` file". Each
cluster's `.backend.hcl` points at the same shared state bucket but a
**unique `key`** (`clusters/<name>/terraform.tfstate`), so each cluster's
state is a fully separate S3 object — not just a namespaced path inside a
shared one. That means switching which cluster you're operating on means
re-pointing the backend, via `-reconfigure`:

```bash
cd main

# stand up the vault cluster
terraform init -reconfigure -backend-config=../tfvars/vault-cluster.backend.hcl
terraform apply -var-file=../tfvars/vault-cluster.tfvars

# switch to prod — this re-targets main/'s backend, it does not touch
# vault-cluster's state
terraform init -reconfigure -backend-config=../tfvars/prod.backend.hcl
terraform apply -var-file=../tfvars/prod.tfvars

# switch back
terraform init -reconfigure -backend-config=../tfvars/vault-cluster.backend.hcl
terraform plan -var-file=../tfvars/vault-cluster.tfvars   # confirms no drift

# add another cluster
cp ../tfvars/prod.tfvars        ../tfvars/staging.tfvars
cp ../tfvars/prod.backend.hcl   ../tfvars/staging.backend.hcl
# edit staging.tfvars: at minimum project_name and vpc_cidr must be unique
# edit staging.backend.hcl: key = "clusters/staging/terraform.tfstate"
terraform init -reconfigure -backend-config=../tfvars/staging.backend.hcl
terraform apply -var-file=../tfvars/staging.tfvars
```

Whichever backend you last ran `terraform init -reconfigure` against is
the one `terraform plan`/`apply`/`destroy`/`output` act on. To check which
that is: `jq .backend.config main/.terraform/terraform.tfstate` prints
the currently configured bucket/key. When in doubt, just re-run
`init -reconfigure -backend-config=...` against the cluster you mean to
target before anything destructive — it's a no-op if you're already
pointed at it.

## Creating the VPC and the cluster separately

By default `main/` creates both the VPC and the EKS cluster in one
`apply`. Two toggles let you split that into separate applies (still one
state, one `tfvars`/`backend.hcl` pair per cluster):

- `create_vpc` (default `true`) — set `false` to skip creating a VPC and
  instead attach the cluster to one that already exists, via
  `existing_vpc_id` / `existing_private_subnet_ids` /
  `existing_public_subnet_ids`.
- `create_eks` (default `true`) — set `false` to apply only the VPC,
  with no cluster yet.

```bash
# stand up just the networking first
terraform apply -var-file=../tfvars/vault-cluster.tfvars -var="create_eks=false"

# ...later, add the cluster on top (same state, same tfvars file)
terraform apply -var-file=../tfvars/vault-cluster.tfvars

# or: point a cluster at a VPC this stack didn't create
terraform apply -var-file=../tfvars/vault-cluster.tfvars \
  -var="create_vpc=false" \
  -var="existing_vpc_id=vpc-0123456789abcdef0" \
  -var='existing_private_subnet_ids=["subnet-aaa","subnet-bbb","subnet-ccc"]' \
  -var='existing_public_subnet_ids=["subnet-ddd","subnet-eee","subnet-fff"]'
```

`create_vpc = false` without `existing_vpc_id`/`existing_private_subnet_ids`
fails at `plan`/`apply` with a clear error (a variable validation rule),
not partway through creating resources.

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
- `create_vpc` / `create_eks` — apply the VPC and the cluster as separate
  steps, or attach the cluster to a VPC this stack didn't create. See
  "Creating the VPC and the cluster separately" above.

## Destroy order

```bash
cd main
terraform init -reconfigure -backend-config=../tfvars/vault-cluster.backend.hcl   # pick the cluster
terraform destroy -var-file=../tfvars/vault-cluster.tfvars

cd ../bootstrap && terraform destroy   # only if you're tearing down the state bucket too
```
