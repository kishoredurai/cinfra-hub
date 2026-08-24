# aws-eks-vpc

Terraform for a VPC (public + private subnets, internet gateway, optional
NAT gateway(s), optional S3 gateway endpoint) and an EKS cluster with a
managed node group, built on top of it.

- `bootstrap/` — one-time root module that creates the S3 bucket used to
  store remote state for `main/`. Uses **local** state itself (chicken-and-egg:
  the bucket has to exist before anything can use it as a backend).
- `main/` — the VPC + EKS stack. State is stored in S3, and locking uses
  Terraform's native S3 lockfile (`use_lockfile = true`, Terraform >= 1.10)
  — no DynamoDB table required.

Versions pinned as of 2026-08-24 (verify current values before applying to
prod — Terraform and EKS both ship new releases regularly):
- Terraform >= 1.15.0 (latest stable: 1.15.8)
- AWS provider ~> 6.57
- `terraform-aws-modules/vpc/aws` ~> 6.6
- `terraform-aws-modules/eks/aws` ~> 21.0
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

### 3. Configure and apply the VPC + EKS stack

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: project_name, CIDRs, AZs, NAT/S3-endpoint toggles,
# cluster_version, node group sizing
terraform plan
terraform apply
```

### 4. Connect kubectl

```bash
$(terraform output -raw configure_kubectl)
```

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

## Destroy order

```bash
cd main && terraform destroy
cd ../bootstrap && terraform destroy   # only if you're tearing down the state bucket too
```
