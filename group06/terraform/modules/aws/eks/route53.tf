## Locals ##
locals {
  lb_route53_values = flatten([
    for lb in keys(var.load_balancers):
    [for zone in var.load_balancers[lb].route53_records:
      [for record in zone.records:
        {
          load_balancer = lb
          zone_id       = zone.zone_id
          self          = zone.self
          name          = record
        }
      ]
    ]
  ])

  lb_route53_keys = flatten([
    for lb in keys(var.load_balancers):
    [for zone in var.load_balancers[lb].route53_records:
      [for record in zone.records:
        "${lb}:${zone.zone_id}:${record}"
      ]
    ]
  ])

  lb_route53_data = zipmap(local.lb_route53_keys, local.lb_route53_values)
}

## Route53 ##
resource "aws_route53_zone" "public" {
  count = var.create_public_route53_zone ? 1 : 0

  name          = "${var.name}.${data.aws_route53_zone.parent[0].name}"
  force_destroy = true

  tags = merge(
    {
      Name = "${var.name}.${data.aws_route53_zone.parent[0].name}"
    },
    local.cluster_tags,
    var.tags
  )
}

resource "aws_route53_zone" "private" {
  count = var.create_private_route53_zone ? 1 : 0

  name          = "${var.name}.${data.aws_route53_zone.parent[0].name}"
  force_destroy = true

  dynamic "vpc" {
    for_each = concat([
      {
        id     = data.aws_vpc.vpc.id
        region = data.aws_region.current.name
      }
    ],
    [for vpc in var.additional_route53_associated_vpcs:
      {
        id     = vpc.id
        region = vpc.region
      }
    ])

    content {
      vpc_id     = vpc.value.id
      vpc_region = vpc.value.region
    }
  }

  tags = merge(
    {
      Name = "${var.name}.${data.aws_route53_zone.parent[0].name}"
    },
    local.cluster_tags,
    var.tags
  )
}

resource "aws_route53_record" "ns" {
  count = anytrue([var.create_public_route53_zone, var.create_private_route53_zone]) ? 1 : 0

  name    = "${var.name}.${data.aws_route53_zone.parent[0].name}"
  type    = "NS"
  ttl     = 300
  zone_id = data.aws_route53_zone.parent[0].id
  records = concat(try(aws_route53_zone.public[0].name_servers, []), try(aws_route53_zone.private[0].name_servers, []))
}

resource "aws_route53_record" "ingress_public" {
  for_each = {
    for lb in keys(var.load_balancers):
      lb => var.load_balancers[lb]
    if var.load_balancers[lb].main_ingress && !var.load_balancers[lb].internal
  }

  name    = ""
  zone_id = aws_route53_zone.public[0].id
  type    = "A"

  alias {
    name                   = aws_lb.ingress[each.key].dns_name
    zone_id                = aws_lb.ingress[each.key].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ingress_private" {
  for_each = {
    for lb in keys(var.load_balancers):
      "ingress" => lb
    if var.load_balancers[lb].main_ingress
  }

  name    = ""
  zone_id = aws_route53_zone.private[0].id
  type    = "A"

  alias {
    name                   = aws_lb.ingress[each.value].dns_name
    zone_id                = aws_lb.ingress[each.value].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "additional" {
  for_each = local.lb_route53_data

  name    = each.value.name
  zone_id = each.value.self ? var.load_balancers[each.value.load_balancer].internal ? aws_route53_zone.private[0].id : aws_route53_zone.public[0].id : each.value.zone_id
  type    = "A"

  alias {
    name                   = aws_lb.ingress[each.value.load_balancer].dns_name
    zone_id                = aws_lb.ingress[each.value.load_balancer].zone_id
    evaluate_target_health = true
  }
}
