output "infra_deploy_role_arn" {
  description = "IAM role ARN for OpenTofu CDN and DNS module deployments"
  value       = aws_iam_role.infra_deploy.arn
}

output "site_deploy_role_arn" {
  description = "IAM role ARN for S3 file sync and CloudFront cache invalidation"
  value       = aws_iam_role.site_deploy.arn
}
