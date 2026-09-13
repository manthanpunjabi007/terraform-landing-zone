data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "admin_trust" {
  statement {
    sid     = "AllowTrustedPrincipalsToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }
  }
}
data "aws_iam_policy_document" "admin_permissions" {
  statement {
    sid    = "OperateLandingZoneServices"
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "cloudtrail:*",
      "config:*",
      "cloudwatch:*",
      "logs:*",
      "sns:*",
      "iam:Get*",
      "iam:List*",
      "budgets:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ProtectTheAuditTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "config:DeleteConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "config:DeleteDeliveryChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "admin" {
  name               = "${var.role_name_prefix}Admin"
  description        = "Operates the landing zone. Cannot disable audit logging or modify IAM."
  assume_role_policy = data.aws_iam_policy_document.admin_trust.json
}

resource "aws_iam_policy" "admin" {
  name        = "${var.role_name_prefix}AdminPolicy"
  description = "Scoped operational access with an explicit deny on audit tampering."
  policy      = data.aws_iam_policy_document.admin_permissions.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = aws_iam_policy.admin.arn
}

resource "aws_iam_role" "readonly" {
  name               = "${var.role_name_prefix}ReadOnly"
  description        = "Read-only access for audit and review."
  assume_role_policy = data.aws_iam_policy_document.admin_trust.json
}
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
data "aws_iam_policy_document" "deploy_trust" {
  statement {
    sid     = "PlaceholderUntilOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }
  }
}

data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid    = "ManageDeploymentArtifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PublishMetricsAndLogs"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.role_name_prefix}Deploy"
  description        = "Deployment role. Trust policy is replaced by GitHub OIDC on Day 11."
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json
}

resource "aws_iam_policy" "deploy" {
  name        = "${var.role_name_prefix}DeployPolicy"
  description = "S3 and CloudWatch access for CI deployments."
  policy      = data.aws_iam_policy_document.deploy_permissions.json
}

resource "aws_iam_role_policy_attachment" "deploy" {
  role       = aws_iam_role.deploy.name
  policy_arn = aws_iam_policy.deploy.arn
}