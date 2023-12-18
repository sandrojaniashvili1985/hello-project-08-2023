resource "aws_elasticache_replication_group" "this" {
  for_each = local.elasticache

  engine                        = "redis"
  engine_version                = each.value.version
  replication_group_id          = "${var.name}-${each.key}"
  replication_group_description = each.value.description
  parameter_group_name          = aws_elasticache_parameter_group.this[each.key].name
  port                          = each.value.port
  node_type                     = each.value.node_type
  number_cache_clusters         = each.value.cluster.cluster_mode ? null : each.value.cluster.node_groups
  automatic_failover_enabled    = each.value.multi_az_enabled || each.value.cluster.cluster_mode ? true : each.value.automatic_failover_enabled
  multi_az_enabled              = each.value.multi_az_enabled
  availability_zones            = length(each.value.availability_zones) > each.value.cluster.node_groups ? slice(each.value.availability_zones, 0, each.value.cluster.node_groups) : each.value.availability_zones
  subnet_group_name             = each.value.subnet_group_name
  security_group_ids            = concat([aws_security_group.this[each.key].id], each.value.security_groups.extra_security_groups)
  apply_immediately             = each.value.apply_immediately
  auto_minor_version_upgrade    = each.value.auto_minor_version_upgrade
  maintenance_window            = each.value.maintenance_window
  notification_topic_arn        = each.value.notification_topic_arn
  auth_token                    = each.value.transit_encryption_enabled ? try(random_password.this[each.key].result, each.value.auth_token) : null
  kms_key_id                    = each.value.at_rest_encryption_enabled ? try(aws_kms_key.this[each.key].id,         each.value.kms_key_id) : null
  transit_encryption_enabled    = each.value.transit_encryption_enabled
  at_rest_encryption_enabled    = each.value.at_rest_encryption_enabled
  snapshot_arns                 = each.value.snapshot_arns
  snapshot_name                 = each.value.snapshot_name
  snapshot_retention_limit      = each.value.snapshot_retention_limit
  snapshot_window               = each.value.snapshot_window
  tags                          = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}"
    }
  )

  dynamic "cluster_mode" {
    for_each = range(each.value.cluster.cluster_mode ? 1 : 0)

    content {
      num_node_groups         = each.value.cluster.node_groups
      replicas_per_node_group = each.value.cluster.replicas_per_node_group
    }
  }
}

resource "aws_elasticache_parameter_group" "this" {
  for_each = local.elasticache

  name        = "${var.name}-${each.key}"
  description = each.value.description
  family      = "redis${join(".", slice(split(".", each.value.version), 0, 2))}"
  tags        = merge(
    each.value.tags,
    {
      Name = "${var.name}-${each.key}"
    }
  )

  dynamic "parameter" {
    iterator = parameter
    for_each = merge(
      each.value.parameters,
      {
        cluster-enabled = each.value.cluster.cluster_mode ? "yes" : "no"
      }
    )

    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

resource "random_password" "this" {
  for_each = {
    for name, config in local.elasticache:
      name => config
    if config.transit_encryption_enabled && config.auth_token == null
  }

  length = 32
}

resource "aws_kms_key" "this" {
  for_each = {
    for name, config in local.elasticache:
      name => config
    if config.create_kms_key && config.at_rest_encryption_enabled && config.kms_key_id == null
  }

  description = "Encryption key for ${each.key} Elasticache"
  tags        = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}_elasticache"
    }
  )
}
