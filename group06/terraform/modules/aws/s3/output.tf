output "name" {
  value = var.name
}

output "vpc" {
  value = var.vpc
}

output "tags" {
  value = var.tags
}

output "s3" {
  value = aws_s3_bucket.this
}

output "s3_bucket_notification" {
  value = aws_s3_bucket_notification.this
}

output "iam" {
  value = aws_iam_role.replication
}

output "kms" {
  value = aws_kms_key.this
}
