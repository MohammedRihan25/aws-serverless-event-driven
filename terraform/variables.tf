variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Base name for serverless resources"
  type        = string
  default     = "enterprise-order-event-platform"
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout (must exceed Lambda consumer timeout)"
  type        = number
  default     = 60
}

variable "max_receive_count" {
  description = "Number of times a message is retried before forwarding to DLQ"
  type        = number
  default     = 3
}
