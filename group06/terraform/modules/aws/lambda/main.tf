resource "aws_lambda_function" "this" {
  for_each = local.lambda

  function_name = each.value.name
  description   = each.value.description
  role          = each.value.iam.role_arn != null ? each.value.iam.role_arn : aws_iam_role.this[each.key].arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  memory_size   = each.value.memory_size_in_mb
  kms_key_arn   = length(each.value.env_vars) > 0 ? try(aws_kms_key.this[each.key].arn, each.value.kms_key_arn) : null
  s3_bucket     = each.value.s3.bucket
  s3_key        = each.value.s3.key
  timeout       = each.value.timeout
  tags          = merge(
    each.value.tags,
    {
      Name = each.value.name
    }
  )

  dynamic "environment" {
    for_each = range(length(each.value.env_vars) > 0 ? 1 : 0)

    content {
      variables = each.value.env_vars
    }
  }

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key
    ]
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_policy.logging,
    aws_iam_role.this
  ]
}

resource "aws_lambda_permission" "this" {
  for_each = local.lambda_permissions

  statement_id   = each.value.name
  function_name  = aws_lambda_function.this[each.value.lambda].arn
  action         = each.value.action
  principal      = each.value.principal
  source_arn     = each.value.source_arn
  source_account = each.value.source_account
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.lambda

  name              = "/aws/lambda/${each.value.name}"
  retention_in_days = each.value.log_retention_in_days
  tags               = merge(
    each.value.tags,
    {
      Name = "/aws/lambda/${each.value.name}"
    }
  )
}

resource "aws_kms_key" "this" {
  for_each = {
    for name, config in local.lambda:
      name => config
    if config.create_kms_key && length(config.env_vars) > 0 && config.kms_key_arn == null
  }

  description = "Encryption key for ${each.key} Lambda"
  tags        = merge(
    each.value.tags,
    {
      Name = "${each.value.name}_lambda"
    }
  )
}
