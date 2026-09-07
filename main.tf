data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "scratch" {
  bucket = "${var.scratch_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

module "networking" {
  source = "./modules/networking"

  vpc_cidr    = "10.0.0.0/16"
  name_prefix = "${var.project_name}-${var.environment}"
}