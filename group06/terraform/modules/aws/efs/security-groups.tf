resource "aws_security_group" "this" {
  for_each = {
    for name, config in local.efs:
      name => config
    if length(concat(config.mount_targets.extra_rules.ingress_with_cidr_blocks, config.mount_targets.extra_rules.ingress_with_source_security_group_id)) > 0
  }

  name_prefix = "${var.name}_${each.key}_efs_"
  vpc_id      = var.vpc.vpc_id
  tags        = merge(
    each.value.tags,
    {
      Name = "${var.name}_${each.key}_efs"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress_default" {
  for_each = {
    for name, config in local.efs:
      name => config
    if length(concat(config.mount_targets.extra_rules.ingress_with_cidr_blocks, config.mount_targets.extra_rules.ingress_with_source_security_group_id)) > 0
  }

  security_group_id = aws_security_group.this[each.key].id
  description       = "Default egress all"
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "ingress" {
  for_each = local.efs_sg_rules

  security_group_id        = aws_security_group.this[each.value.efs].id
  description              = each.value.description
  type                     = "ingress"
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  cidr_blocks              = lookup(each.value, "cidr_blocks",              null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}
