
terraform {
  backend "s3" {
    bucket         = "iamnagasatya-terraform-backend-s3-bucket"
    key            = "globalstate/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "iamnagasatya-terraform-backend-dynamodb-table"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "backend_bucket" {
  bucket        = "iamnagasatya-terraform-backend-s3-bucket"
  force_destroy = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_bucket_ssd_enc" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "backend_bucket_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "iamnagasatya-terraform-backend-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}