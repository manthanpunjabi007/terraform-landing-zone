output "scratch_bucket_arn" {
  description = "ARN of the scratch bucket."
  value       = aws_s3_bucket.scratch.arn
}

output "account_id" {
  description = "AWS account ID Terraform is authenticated against."
  value       = data.aws_caller_identity.current.account_id
}
output "subnet_ids_by_tier" {
  description = "Subnet IDs grouped by tier."
  value       = module.networking.subnet_ids_by_tier
}