terraform {
  backend "s3" {
    bucket         = "bodytechsolutions-tfstate-dns"
    key            = "dns/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bodytechsolutions-tfstate-dns-lock"
  }
}