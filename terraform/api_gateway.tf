# ========================================================
# HTTP API Gateway (v2)
# ========================================================
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-http-api"
  }
}

# ========================================================
# API Gateway Stage ($default with Auto Deploy)
# ========================================================
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name = "${var.project_name}-default-stage"
  }
}

# ========================================================
# Lambda Proxy Integration
# ========================================================
resource "aws_apigatewayv2_integration" "producer_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.producer.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ========================================================
# API Gateway Route: POST /orders
# ========================================================
resource "aws_apigatewayv2_route" "orders_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.producer_integration.id}"
}

# ========================================================
# Lambda Execution Permission from API Gateway
# ========================================================
resource "aws_lambda_permission" "api_gw_invoke_producer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
