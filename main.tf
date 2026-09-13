data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "scratch" {
  bucket = "${var.scratch_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

module "networking" {
  source = "./modules/networking"

  vpc_cidr    = "10.0.0.0/16"
  name_prefix = "${var.project_name}-${var.environment}"
  subnets = {
    "public-a"   = { cidr = "10.0.0.0/24", az_index = 0, tier = "public" }
    "public-b"   = { cidr = "10.0.1.0/24", az_index = 1, tier = "public" }
    "private-a"  = { cidr = "10.0.10.0/24", az_index = 0, tier = "private" }
    "private-b"  = { cidr = "10.0.11.0/24", az_index = 1, tier = "private" }
    "isolated-a" = { cidr = "10.0.20.0/24", az_index = 0, tier = "isolated" }
    "isolated-b" = { cidr = "10.0.21.0/24", az_index = 1, tier = "isolated" }
  }
}
module "iam" {
  source = "./modules/iam"

  role_name_prefix       = "LandingZone"
  trusted_principal_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform-admin"]
}
