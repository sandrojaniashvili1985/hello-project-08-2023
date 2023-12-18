resource "aws_iam_role" "replication" {
  for_each = {
    for name, config in local.s3:
      name => config
    if length(config.replication) > 0
  }

  name               = "${each.value.prefix}${var.name}-${each.key}-s3-replication"
  description        = "S3 Bucket replication role for ${each.value.prefix}${var.name}-${each.key}"
  tags               = merge(
    each.value.tags,
    {
      Name = "${each.value.prefix}${var.name}-${each.key}-s3-replication"
    }
  )
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  for_each = {
    for name, config in local.s3:
      name => config
    if length(config.replication) > 0
  }

  role       = aws_iam_role.replication[each.key].name
  policy_arn = aws_iam_policy.replication[each.key].arn
}

resource "aws_iam_policy" "replication" {
  for_each = {
    for name, config in local.s3:
      name => config
    if length(config.replication) > 0
  }

  name        = "${each.value.prefix}${var.name}-${each.key}-s3-replication"
  description = "S3 Bucket replication policy for ${each.value.prefix}${var.name}-${each.key}"
  tags        = merge(
    each.value.tags,
    {
      Name = "${each.value.prefix}${var.name}-${each.key}-s3-replication"
    }
  )
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.this[each.key].arn}"
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.this[each.key].arn}/*"
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": ${jsonencode(formatlist("%s/*", tolist([for name, config in each.value.replication: config.destination.bucket])))}
    }
  ]
}
POLICY
}
