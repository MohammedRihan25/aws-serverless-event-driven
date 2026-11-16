# ========================================================
# CloudWatch Alarm: Dead Letter Queue (DLQ) Message Depth
# Alerts when any poison-pill message fails 3 retries
# ========================================================
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "${var.project_name}-dlq-messages-detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm triggers when one or more messages land in the Dead Letter Queue (DLQ)"

  dimensions = {
    QueueName = aws_sqs_queue.orders_dlq.name
  }

  tags = {
    Severity = "Critical"
  }
}

# ========================================================
# CloudWatch Alarm: Consumer Lambda Errors
# ========================================================
resource "aws_cloudwatch_metric_alarm" "consumer_errors" {
  alarm_name          = "${var.project_name}-consumer-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when any unhandled error occurs in the SQS consumer Lambda"

  dimensions = {
    FunctionName = aws_lambda_function.consumer.function_name
  }

  tags = {
    Severity = "High"
  }
}
