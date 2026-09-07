output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "Availability zones available in this region."
  value       = data.aws_availability_zones.available.names
}
output "subnet_ids_by_tier" {
  description = "Map of tier name to the list of subnet IDs in that tier."
  value = {
    for tier in distinct([for s in var.subnets : s.tier]) :
    tier => [for k, v in var.subnets : aws_subnet.this[k].id if v.tier == tier]
  }
}