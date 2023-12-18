output "name" {
  value = var.name
}

output "vpc" {
  value = var.vpc
}

output "tags" {
  value = var.tags
}

output "lambda" {
  value = aws_lambda_function.this
}

output "iam_role" {
  value = aws_iam_role.this
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.this
}

output "kms" {
  value = aws_kms_key.this
}
