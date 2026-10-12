terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.untagged]
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

locals {
  function_name = "${var.service_name}-${var.environment}"
}

# Package only the compiled handler, keeping the ZIP outside dist/.
data "archive_file" "api" {
  type        = "zip"
  source_file = var.bundle_path
  output_path = "${path.root}/api.zip"
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
}

# Only the Lambda service can assume this runtime role.
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${local.function_name}-runtime"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# The log group is created by Terraform, so Lambda only needs
# permission to create streams and write events inside it.
data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.api.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "logging" {
  name   = "write-function-logs"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.logging.json
}

resource "aws_lambda_function" "api" {
  function_name = local.function_name
  role          = aws_iam_role.api.arn

  runtime       = "nodejs22.x"
  handler       = "handler.handler"
  architectures = ["arm64"]

  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      APP_ENV   = var.environment
      LOG_LEVEL = var.log_level
    }
  }

  depends_on = [aws_iam_role_policy.logging]
}

output "function_name" {
  value = aws_lambda_function.api.function_name
}

output "function_arn" {
  value = aws_lambda_function.api.arn
}