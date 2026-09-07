variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to the Name tag of every resource in this module."
  type        = string
}
variable "subnets" {
  description = "Subnets to create. Key is the name suffix; az_index selects which availability zone."
  type = map(object({
    cidr     = string
    az_index = number
    tier     = string
  }))
}