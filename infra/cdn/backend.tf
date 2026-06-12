terraform {
  backend "s3" {
    bucket         = "bodytechsolutions-tfstate-cdn"
    key            = "cdn/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bodytechsolutions-tfstate-cdn-lock"
  }
}