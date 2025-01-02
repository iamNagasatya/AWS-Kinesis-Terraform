output "account_id" {
  value       = data.aws_caller_identity.aws_acc.account_id
  description = "AWS Account ID"
  sensitive   = true
}

output "source_bucket_id" {
  value = aws_s3_bucket.buckets[var.buckets_list[0]].bucket
  description = "S3 Source Bucket"
}

output "backup_bucket_id" {
  value = aws_s3_bucket.buckets[var.buckets_list[1]].bucket
  description = "S3 Backup Bucket"
}

output "Kinesis_Data_Stream_ARN" {
  value = aws_kinesis_stream.kds.arn
  description = "Kinesis Data Stream ARN"
}

output "Firehose_ARN" {
  value = aws_kinesis_firehose_delivery_stream.firehose.arn
  description = "Firehose ARN"
}

output "Lambda_Function_ARN" {
  value = aws_lambda_function.my_lambda_function.arn
  description = "Lambda Function ARN"
}