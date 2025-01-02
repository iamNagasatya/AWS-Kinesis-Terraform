variable "buckets_list" {
  type        = list(string)
  description = "List of Buckets for Kinesis to use"
  default     = ["kinesis-s3-source", "kinesis-s3-backup"]
}
variable "firehose_name" {
  description = "The name of the Kinesis Firehose delivery stream"
  type        = string
  default     = "kinesis-firehose-iamnagasatya"
}