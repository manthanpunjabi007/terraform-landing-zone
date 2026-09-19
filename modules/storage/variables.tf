variable "name_prefix" {
  description = "Prefix for bucket names. Account ID is appended for global uniqueness."
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets. Demo environments only."
  type        = bool
  default     = false
}