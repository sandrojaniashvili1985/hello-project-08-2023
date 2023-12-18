data "aws_iam_policy_document" "ecr_endpoint_policy" {
  statement {
    sid    = "AllowAll"
    effect = "Allow"
    actions = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_subnet_ids" "public_per_az" {
  for_each = toset(var.availability_zones)

  vpc_id = module.vpc.vpc_id

  filter {
    name   = "availability-zone"
    values = [each.value]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.name}-public-${each.value}"]
  }

  depends_on = [module.vpc]
}



data "aws_subnet_ids" "private_per_az" {
  for_each = toset(var.availability_zones)

  vpc_id = module.vpc.vpc_id

  filter {
    name   = "availability-zone"
    values = [each.value]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.name}-private-${each.value}"]
  }

  depends_on = [module.vpc]
}
