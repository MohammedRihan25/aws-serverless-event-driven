output "api_endpoint" {
  description = "Base URL of the HTTP API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "orders_post_url" {
  description = "Public URL to POST order transactions"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}orders"
}

output "sqs_queue_url" {
  description = "Primary SQS queue URL"
  value       = aws_sqs_queue.orders_queue.id
}

output "sqs_queue_arn" {
  description = "Primary SQS queue ARN"
  value       = aws_sqs_queue.orders_queue.arn
}

output "dlq_url" {
  description = "Dead Letter Queue URL for failed messages"
  value       = aws_sqs_queue.orders_dlq.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB Orders Table"
  value       = aws_dynamodb_table.orders.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB Orders Table"
  value       = aws_dynamodb_table.orders.arn
}

output "producer_function_name" {
  description = "Name of the Producer Lambda"
  value       = aws_lambda_function.producer.function_name
}

output "consumer_function_name" {
  description = "Name of the Consumer Lambda"
  value       = aws_lambda_function.consumer.function_name
}
