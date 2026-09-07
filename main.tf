data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "scratch" {
  bucket = "${var.scratch_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}