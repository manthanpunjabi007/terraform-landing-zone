variable "role_name_prefix" {
  description = "Prefix for every role name created by this module."
  type        = string
}

variable "trusted_principal_arns" {
  description = "ARNs permitted to assume the Admin and ReadOnly roles."
  type        = list(string)
}