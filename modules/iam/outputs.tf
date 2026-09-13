output "role_arns" {
  description = "Map of role name to ARN."
  value = {
    admin    = aws_iam_role.admin.arn
    readonly = aws_iam_role.readonly.arn
    deploy   = aws_iam_role.deploy.arn
  }
}

