locals {
  monitored_metrics = {
    lambda-errors = {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      dimensions = {
        FunctionName = aws_lambda_function.api.function_name
      }
      description = "Lambda invocation failures; inspect function logs."
    }

    lambda-throttles = {
      namespace   = "AWS/Lambda"
      metric_name = "Throttles"
      dimensions = {
        FunctionName = aws_lambda_function.api.function_name
      }
      description = "Lambda throttling; inspect concurrency and traffic."
    }

    api-5xx = {
      namespace   = "AWS/ApiGateway"
      metric_name = "5xx"
      dimensions = {
        ApiId = aws_apigatewayv2_api.api.id
      }
      description = "API server errors, including handled 503 responses."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "service" {
  for_each = local.monitored_metrics

  alarm_name        = "${local.function_name}-${each.key}"
  alarm_description = each.value.description

  namespace   = each.value.namespace
  metric_name = each.value.metric_name
  dimensions  = each.value.dimensions

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
}