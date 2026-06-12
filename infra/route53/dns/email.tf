# MX Records — Google Workspace mail servers
resource "aws_route53_record" "mx" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
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

# SPF — authorizes Google to send on behalf of your domain
resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600

  records = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}

# DKIM — paste value from Google Workspace Admin after generating the key
resource "aws_route53_record" "dkim" {
  zone_id = var.route53_zone_id
  name    = "google._domainkey.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600

  records = [
    var.google_dkim_value
  ]
}

# DMARC — tells receiving servers what to do with unauthenticated mail
resource "aws_route53_record" "dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600

  records = [
    "v=DMARC1; p=quarantine; rua=mailto:aubre@${var.domain_name}; ruf=mailto:aubre@${var.domain_name}; fo=1"
  ]
}