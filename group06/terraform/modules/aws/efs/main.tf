resource "aws_efs_file_system" "this" {
  for_each = local.efs

  creation_token                  = "${var.name}_${each.key}"
  availability_zone_name          = each.value.availability_zone_name
  encrypted                       = each.value.encrypted
  kms_key_id                      = each.value.create_kms_key && each.value.encrypted ? aws_kms_key.this[each.key].arn : each.value.kms_key_id
  performance_mode                = each.value.performance_mode
  throughput_mode                 = each.value.throughput_mode
  provisioned_throughput_in_mibps = each.value.throughput_mode == "provisioned" ? each.value.provisioned_throughput_in_mibps : null
  tags = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}"
    }
  )

  dynamic "lifecycle_policy" {
    for_each = range(each.value.lifecycle_policy != null ? 1 : 0)

    content {
      transition_to_ia = each.value.lifecycle_policy.transition_to_ia
    }
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = local.efs_mount

  file_system_id  = aws_efs_file_system.this[each.value.efs].id
  subnet_id       = each.value.subnet_id
  security_groups = concat(each.value.extra_security_groups, try([aws_security_group.this[each.value.efs].id], []))
}

resource "aws_kms_key" "this" {
  for_each = {
    for name, config in local.efs :
    name => config
    if config.create_kms_key && config.encrypted
  }

  description = "Encryption key for ${each.key} EFS"
  tags = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}_efs"
    }
  )
}
