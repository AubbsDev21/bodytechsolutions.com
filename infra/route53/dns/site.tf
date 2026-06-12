data "terraform_remote_state" "cdn" {
  backend = "s3"

  config = {
    bucket = "bodytechsolutions-tfstate-cdn"
    key    = "cdn/terraform.tfstate"
    region = "us-east-1"
  }
}

# A record — points bodytechsolutions.com to CloudFront distribution
resource "aws_route53_record" "site" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.cdn.outputs.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# www — points www.bodytechsolutions.com to CloudFront
resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.cdn.outputs.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
