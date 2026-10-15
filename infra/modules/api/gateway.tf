resource "aws_apigatewayv2_api" "api" {
  name          = local.function_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id = aws_apigatewayv2_api.api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Forward requests to Lambda; the TypeScript handler selects the endpoint.
resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "$default"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_lambda_permission" "gateway" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  provider    = aws.untagged
  default_route_settings {
    throttling_rate_limit  = var.api_rate_limit
    throttling_burst_limit = var.api_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn

    format = jsonencode({
      requestId         = "$context.requestId"
      requestTime       = "$context.requestTime"
      method            = "$context.httpMethod"
      route             = "$context.routeKey"
      status            = "$context.status"
      responseLatencyMs = "$context.responseLatency"
      responseLength    = "$context.responseLength"
    })
  }

  depends_on = [
    aws_apigatewayv2_route.default,
    aws_lambda_permission.gateway
  ]
}

output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}