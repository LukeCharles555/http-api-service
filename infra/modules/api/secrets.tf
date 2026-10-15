resource "aws_secretsmanager_secret" "downstream" {
  name                    = "${local.function_name}/downstream"
  description             = "Demo downstream credential for ${var.environment}"
  recovery_window_in_days = 7
}

data "aws_iam_policy_document" "read_secret" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      aws_secretsmanager_secret.downstream.arn
    ]
  }
}

resource "aws_iam_role_policy" "read_secret" {
  name   = "read-downstream-secret"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.read_secret.json
}

output "secret_arn" {
  value = aws_secretsmanager_secret.downstream.arn
}