# ========================================================
# Packaging Lambda Code Archives
# ========================================================
data "archive_file" "producer_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/producer.py"
  output_path = "${path.module}/.build/producer.zip"
}

data "archive_file" "consumer_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/consumer.py"
  output_path = "${path.module}/.build/consumer.zip"
}

# ========================================================
# Producer Lambda Function (API Gateway -> SQS)
# ========================================================
resource "aws_lambda_function" "producer" {
  function_name    = "${var.project_name}-producer"
  filename         = data.archive_file.producer_zip.output_path
  source_code_hash = data.archive_file.producer_zip.output_base64sha256
  role             = aws_iam_role.producer_role.arn
  handler          = "producer.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ORDER_QUEUE_URL = aws_sqs_queue.orders_queue.id
      ENVIRONMENT     = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-producer"
  }
}

# ========================================================
# Consumer Lambda Function (SQS -> DynamoDB)
# ========================================================
resource "aws_lambda_function" "consumer" {
  function_name    = "${var.project_name}-consumer"
  filename         = data.archive_file.consumer_zip.output_path
  source_code_hash = data.archive_file.consumer_zip.output_base64sha256
  role             = aws_iam_role.consumer_role.arn
  handler          = "consumer.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 512

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ORDERS_TABLE_NAME = aws_dynamodb_table.orders.name
      ENVIRONMENT       = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-consumer"
  }
}

# ========================================================
# SQS Event Source Mapping with Partial Batch Failure Reporting
# ========================================================
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.orders_queue.arn
  function_name                      = aws_lambda_function.consumer.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 50
  }
}
