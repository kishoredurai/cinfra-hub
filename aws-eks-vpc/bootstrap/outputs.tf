output "state_bucket_name" {
  description = "Name of the S3 bucket to reference from main/backend.hcl."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}
