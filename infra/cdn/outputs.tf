output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name — feeds into infra/dns site.tf"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — used for cache invalidation on deploy"
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for site files"
  value       = aws_s3_bucket.site.id
}