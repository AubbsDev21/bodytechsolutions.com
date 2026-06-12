output "mx_fqdn" {
  description = "Fully qualified domain name for the MX record"
  value       = aws_route53_record.mx.fqdn
}

output "dkim_fqdn" {
  description = "Fully qualified domain name for the DKIM record"
  value       = aws_route53_record.dkim.fqdn
}

output "site_fqdn" {
  description = "Fully qualified domain name for the site A record"
  value       = aws_route53_record.site.fqdn
}

output "www_fqdn" {
  description = "Fully qualified domain name for the www A record"
  value       = aws_route53_record.www.fqdn
}