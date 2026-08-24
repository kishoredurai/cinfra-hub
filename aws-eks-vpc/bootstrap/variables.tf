variable "aws_region" {
  description = "AWS region to create the state bucket in."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique name for the S3 bucket that will hold Terraform remote state for the main/ root module."
  type        = string
}

variable "tags" {
  description = "Tags applied to the state bucket."
  type        = map(string)
  default     = {}
}
