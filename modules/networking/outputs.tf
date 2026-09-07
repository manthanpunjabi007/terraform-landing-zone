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