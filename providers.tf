terraform {
  backend "s3" {
    bucket         = "nagasatya-terraform-backend-s3-bucket"
    key            = "globalstate/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "nagasatya-terraform-backend-dynamodb-table"
    encrypt        = true
  }
}


provider "aws" {
  region = var.aws_region
}
