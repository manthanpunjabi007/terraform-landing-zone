variable "aws_region" {
  description = "AWS region all resources are created in."
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Short name used as a prefix and in tags."
  type        = string
  default     = "secure-landing-zone"
}

variable "environment" {
  description = "Deployment environment. Feeds the provider default_tags block."
  type        = string
  default     = "demo"

  validation {
    condition     = contains(["dev", "demo", "prod"], var.environment)
    error_message = "environment must be one of: dev, demo, prod."
  }
}

variable "scratch_bucket_prefix" {
  description = "Name prefix for the scratch bucket. Account ID is appended for global uniqueness."
  type        = string
  default     = "tf-scratch"
}