# ========================================================
# SQS Dead Letter Queue (DLQ) for Poisoned Messages
# ========================================================
resource "aws_sqs_queue" "orders_dlq" {
  name                      = "${var.project_name}-orders-dlq"
  message_retention_seconds = 1209600 # 14 days retention for inspection
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "${var.project_name}-orders-dlq"
    Type = "DeadLetterQueue"
  }
}

# ========================================================
# SQS Primary Orders Processing Queue
# ========================================================
resource "aws_sqs_queue" "orders_queue" {
  name                       = "${var.project_name}-orders-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = 345600 # 4 days
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name = "${var.project_name}-orders-queue"
    Type = "PrimaryQueue"
  }
}

# Allow Primary Queue to redrive messages to DLQ
resource "aws_sqs_queue_redrive_allow_policy" "dlq_policy" {
  queue_url = aws_sqs_queue.orders_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.orders_queue.arn]
  })
}
