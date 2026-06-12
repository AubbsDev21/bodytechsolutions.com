variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for bodytechsolutions.com"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "bodytechsolutions.com"
}

variable "google_dkim_value" {
  description = "DKIM TXT record value from Google Workspace Admin > Apps > Gmail > Authenticate email"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment (development or production)"
  type        = string
}