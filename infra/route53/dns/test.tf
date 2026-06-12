# infra/email.tf
# Google Workspace DNS records for bodytechsolutions.com
# All sensitive values pulled from GitHub Secrets via TF_VAR_ env vars
# Run: tofu apply -target=module.email or via deploy-email.yml workflow

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for bodytechsolutions.com"
  type        = string
  sensitive   = true
}

variable "google_dkim_value" {
  description = "Google DKIM TXT record value from Google Workspace Admin"
  type        = string
  sensitive   = true
}

# MX Records — Google Workspace mail servers
resource "aws_route53_record" "mx" {
  zone_id = var.route53_zone_id
  name    = "bodytechsolutions.com"
  type    = "MX"
  ttl     = 3600

  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com.",
  ]
}

# SPF Record — authorizes Google to send on behalf of your domain
resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = "bodytechsolutions.com"
  type    = "TXT"
  ttl     = 3600

  records = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}

# DKIM Record — paste value from Google Workspace Admin > Apps > Gmail > Authenticate email
resource "aws_route53_record" "dkim" {
  zone_id = var.route53_zone_id
  name    = "google._domainkey.bodytechsolutions.com"
  type    = "TXT"
  ttl     = 3600

  records = [
    var.google_dkim_value
  ]
}

# DMARC Record — tells receiving servers what to do with unauthenticated mail
resource "aws_route53_record" "dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.bodytechsolutions.com"
  type    = "TXT"
  ttl     = 3600

  records = [
    "v=DMARC1; p=quarantine; rua=mailto:aubre@bodytechsolutions.com; ruf=mailto:aubre@bodytechsolutions.com; fo=1"
  ]
}

# Google Workspace domain verification record
# Get this value from Google Workspace Admin > Setup > Verify domain
resource "aws_route53_record" "google_verification" {
  zone_id = var.route53_zone_id
  name    = "bodytechsolutions.com"
  type    = "TXT"
  ttl     = 3600

  records = [
    # Add your Google verification token here as a GitHub secret
    # Format: "google-site-verification=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    var.google_workspace_verification
  ]
}

variable "google_workspace_verification" {
  description = "Google Workspace domain verification TXT record value"
  type        = string
  sensitive   = true
}
