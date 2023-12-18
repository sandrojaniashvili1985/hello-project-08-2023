## Locals ##
locals {
  lb_targets_values = flatten([
    for lb in keys(var.load_balancers):
    [for target in keys(var.load_balancers[lb].targets):
      {
        load_balancer = lb
        name          = target
        target        = var.load_balancers[lb].targets[target]
      }
    ]
  ])

  lb_targets_keys = flatten([
    for lb in keys(var.load_balancers):
    [for target in keys(var.load_balancers[lb].targets):
      "${lb}:${target}"
    ]
  ])

  lb_targets_data = zipmap(local.lb_targets_keys, local.lb_targets_values)


  lb_targets_acm_values = flatten([
    for lb in keys(var.load_balancers):
    [for target in keys(var.load_balancers[lb].targets):
      [for cert in var.load_balancers[lb].targets[target].acm_certificate_arns:
        {
          load_balancer = lb
          target        = target
          cert          = cert
        } if index(var.load_balancers[lb].targets[target].acm_certificate_arns, cert) != 0
      ]
    ]
  ])

  lb_targets_acm_keys = flatten([
    for lb in keys(var.load_balancers):
    [for target in keys(var.load_balancers[lb].targets):
      [for cert in var.load_balancers[lb].targets[target].acm_certificate_arns:
        "${lb}:${target}:${cert}"
        if index(var.load_balancers[lb].targets[target].acm_certificate_arns, cert) != 0
      ]
    ]
  ])

  lb_targets_acm_data = zipmap(local.lb_targets_acm_keys, local.lb_targets_acm_values)
}

## Ingress LB ##
resource "aws_lb" "ingress" {
  for_each = var.load_balancers

  name               = "${var.name}-${each.key}"
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  security_groups    = local.network_lb[each.key]     ? null                    : [module.ingress_alb_sg.this_security_group_id, aws_security_group.lb[each.key].id]
  subnets            = each.value.internal            ? var.private_subnets     : var.public_subnets
  idle_timeout       = local.application_lb[each.key] ? each.value.idle_timeout : null

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    each.value.tags,
    var.tags
  )
}

## Ingress Listeners ##
resource "aws_lb_listener" "ingress" {
  for_each = local.lb_targets_data

  load_balancer_arn = aws_lb.ingress[each.value.load_balancer].arn
  port              = each.value.target.listener_port
  protocol          = upper(each.value.target.listener_protocol)
  ssl_policy        = contains(["HTTPS", "TLS"], upper(each.value.target.listener_protocol)) ? "ELBSecurityPolicy-2016-08"                : null
  certificate_arn   = contains(["HTTPS", "TLS"], upper(each.value.target.listener_protocol)) ?  each.value.target.acm_certificate_arns[0] : null

  dynamic "default_action" {
    for_each = range(each.value.target.default_action.type == "redirect" ? 1 : 0)

    content {
      type = each.value.target.default_action.type

      redirect {
        port        = each.value.target.default_action.action.port
        protocol    = each.value.target.default_action.action.protocol
        status_code = each.value.target.default_action.action.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = range(each.value.target.default_action.type == "forward" ? 1 : 0)

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.ingress[each.key].arn
    }
  }
}

## Ingress Listeners ACM ##
resource "aws_alb_listener_certificate" "ingress" {
  for_each = local.lb_targets_acm_data

  listener_arn    = aws_lb_listener.ingress["${each.value.load_balancer}:${each.value.target}"].arn
  certificate_arn = each.value.cert
}

## Ingress Target Groups ##
resource "aws_lb_target_group" "ingress" {
  for_each = {
    for target in keys(local.lb_targets_data):
      target => local.lb_targets_data[target]
    if local.lb_targets_data[target].target.default_action.type == "forward"
  }

  name                 = "${var.name}-${each.value.load_balancer}-${each.value.name}"
  port                 = each.value.target.target_port
  protocol             = each.value.target.target_protocol
  vpc_id               = var.vpc_id
  target_type          = each.value.target.target_type
  deregistration_delay = each.value.target.deregistration_delay
  proxy_protocol_v2    = each.value.target.proxy_protocol_v2

  dynamic "health_check" {
    for_each = range(upper(each.value.target.health_check.protocol) == "TCP" ? 1 : 0)

    content {
      protocol            = lookup(each.value.target.health_check, "protocol",          null)
      port                = lookup(each.value.target.health_check, "port",              null)
      healthy_threshold   = lookup(each.value.target.health_check, "healthy_threshold", null)
      interval            = lookup(each.value.target.health_check, "interval",          null)
    }
  }

  dynamic "health_check" {
    for_each = range(upper(each.value.target.health_check.protocol) != "TCP" ? 1 : 0)

    content {
      protocol            = lookup(each.value.target.health_check, "protocol",            null)
      path                = lookup(each.value.target.health_check, "path",                null)
      port                = lookup(each.value.target.health_check, "port",                null)
      matcher             = lookup(each.value.target.health_check, "matcher",             null)
      unhealthy_threshold = lookup(each.value.target.health_check, "unhealthy_threshold", null)
      healthy_threshold   = lookup(each.value.target.health_check, "healthy_threshold",   null)
      timeout             = lookup(each.value.target.health_check, "timeout",             null)
      interval            = lookup(each.value.target.health_check, "interval",            null)
    }
  }

  dynamic "stickiness" {
    for_each = range(local.application_lb[each.value.load_balancer] ? 1 : 0)

    content {
      type            = "lb_cookie"
      enabled         = lookup(each.value.target.stickiness, "enabled", false)
      cookie_duration = lookup(each.value.target.stickiness, "cookie_duration", null)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${each.value.load_balancer}-${each.value.name}"
    },
    var.load_balancers[each.value.load_balancer].tags,
    var.tags
  )
}
