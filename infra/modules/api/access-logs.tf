resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/${local.function_name}"
  retention_in_days = var.log_retention_days
}