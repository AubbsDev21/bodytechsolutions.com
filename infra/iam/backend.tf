terraform {
  backend "s3" {
    bucket         = "bodytechsolutions-tfstate-iam"
    key            = "iam/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bodytechsolutions-tfstate-iam-lock"
  }
}