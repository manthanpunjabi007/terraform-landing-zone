data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "scratch" {
  bucket = "tf-scratch-${data.aws_caller_identity.current.account_id}"
}