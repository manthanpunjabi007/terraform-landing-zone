variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to the Name tag of every resource in this module."
  type        = string
}