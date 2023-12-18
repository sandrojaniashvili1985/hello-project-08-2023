resource "aws_iam_role" "this" {
  for_each = {
    for name, config in local.lambda:
      name => config
    if config.iam.manage_iam
  }

  name               = "${each.value.name}_lambda"
  tags               = merge(
    each.value.tags,
    {
      Name = "${each.value.name}_lambda"
    }
  )
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "logging" {
  for_each = {
    for name, config in local.lambda:
      name => config
    if config.iam.manage_iam
  }

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.logging[0].arn
}

resource "aws_iam_policy" "logging" {
  count = length({
    for name, config in local.lambda:
      name => config
    if config.iam.manage_iam
  }) > 0 ? 1 : 0

  name        = "${var.name}_lambda_logging"
  description = "IAM policy for logging from a lambda"
  tags        = merge(
    local.lambda_defaults.tags,
    {
      Name = "${var.name}_lambda_logging"
    }
  )
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "extra" {
  for_each = local.lambda_extra_policies

  name        = "${var.name}_${each.value.lambda}_${each.value.name}"
  description = each.value.description
  policy      = each.value.policy
  tags        = merge(
    local.lambda_defaults.tags,
    {
      Name = "${var.name}_${each.value.lambda}_${each.value.name}"
    }
  )
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = local.lambda_extra_policies

  role       = aws_iam_role.this[each.value.lambda].name
  policy_arn = aws_iam_policy.extra[each.key].arn
}

data "aws_iam_policy" "managed" {
  for_each = local.lambda_managed_policies

  name = each.value.name
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.lambda_managed_policies

  role       = aws_iam_role.this[each.value.lambda].name
  policy_arn = data.aws_iam_policy.managed[each.key].arn
}
