# One-time bootstrap: creates the S3 bucket used as the remote backend
# (state storage + native S3 locking via `use_lockfile`) for the main/
# root module. This root module keeps its own state locally — it must
# exist before main/ can init against it.

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Purpose = "terraform-remote-state"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
