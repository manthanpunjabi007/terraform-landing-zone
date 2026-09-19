output "data_bucket_name" {
  description = "Name of the secure data bucket."
  value       = aws_s3_bucket.data.id
}

output "log_bucket_name" {
  description = "Name of the CloudTrail log bucket."
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "ARN of the log bucket, for the CloudTrail trail."
  value       = aws_s3_bucket.logs.arn
}