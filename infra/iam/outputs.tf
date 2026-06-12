output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — used as AWS_DEFAULT_ACCOUNT-based role-to-assume in workflows"
  value       = aws_iam_role.github_actions.arn
}