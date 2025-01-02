# Get AWS account details
data "aws_caller_identity" "aws_acc" {}

# Create S3 Source Bucket for Kinesis Source
resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.buckets_list)
  bucket   = join("-", [each.value, data.aws_caller_identity.aws_acc.account_id])
  force_destroy = true
  tags = {
    createdBy = "iamnagasatya"
  }
}

# Create Kinesis Data Stream
resource "aws_kinesis_stream" "kds" {
  name        = "kds"
  shard_count = 2
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
  tags = {
    createdBy = "iamnagasatya"
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_to_firehose" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  depends_on = [aws_iam_role.firehose_role]
}

resource "aws_iam_role_policy_attachment" "kinesis_full_access_to_firehose" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  depends_on = [aws_iam_role.firehose_role]
}

# Lambda role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_to_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  depends_on = [aws_iam_role.lambda_role]
}

resource "aws_iam_role_policy_attachment" "kinesis_full_access_to_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  depends_on = [aws_iam_role.lambda_role]
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_to_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  depends_on = [aws_iam_role.lambda_role]
}

# create log group
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${var.firehose_name}"
  retention_in_days = 7
}

# create log stream
resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
  depends_on     = [aws_cloudwatch_log_group.firehose_log_group]
}

# create firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.firehose_name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kds.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.buckets["kinesis-s3-backup"].arn
    buffering_interval = 60
    buffering_size     = 1

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }
  }

  tags = {
    desc = "Created by iamnagasatya"
  }
  depends_on = [aws_kinesis_stream.kds, aws_iam_role.firehose_role, aws_cloudwatch_log_group.firehose_log_group, aws_cloudwatch_log_stream.firehose_log_stream]
}

# create lambda function
resource "aws_lambda_function" "my_lambda_function" {
  filename         = "lambda_function.zip"
  function_name    = "letsdo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
  description      = "My Lambda function created by iamnagasatya"
  timeout          = 120
  memory_size      = 900
  publish          = true
}


# remaining

resource "aws_lambda_permission" "s3_invoke_permission" {
  statement_id   = "S3InvokePermission"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.my_lambda_function.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.buckets["kinesis-s3-source"].arn
  source_account = data.aws_caller_identity.aws_acc.account_id
  depends_on     = [aws_lambda_function.my_lambda_function]
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.buckets["kinesis-s3-source"].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda_function.arn
    events              = ["s3:ObjectCreated:Put"]
  }
  depends_on = [aws_lambda_function.my_lambda_function]
}
