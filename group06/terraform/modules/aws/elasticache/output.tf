output "name" {
  value = var.name
}

output "vpc" {
  value = var.vpc
}

output "tags" {
  value = var.tags
}

output "elasticache" {
  value = aws_elasticache_replication_group.this
}

output "security_groups" {
  value = aws_security_group.this
}

output "kms" {
  value = aws_kms_key.this
}
