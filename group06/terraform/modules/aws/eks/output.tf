## General ##
output "name" {
  value = var.name
}

output "cluster_id" {
  value = aws_eks_cluster.cluster.id
}

output "ingress_fqdn" {
  value = local.ingress_fqdn
}

output "cluster_api_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}


## Kubeconfig ##
output "kube_config" {
  value = replace(local.eks_kube_config, "\r\n", "\n")
}

output "kube_ca_crt" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}


## Load Balancers ##
output "load_balancers" {
  value = {
    for lb in keys(aws_lb.ingress):
      lb => {
        id         = aws_lb.ingress[lb].id
        arn        = aws_lb.ingress[lb].arn
        arn_suffix = aws_lb.ingress[lb].arn_suffix
      }
  }
}

output "listeners" {
  value = {
    for listener in keys(aws_lb_listener.ingress):
      listener => {
        id         = aws_lb_listener.ingress[listener].id
        arn        = aws_lb_listener.ingress[listener].arn
        arn_suffix = aws_lb_listener.ingress[listener].load_balancer_arn
      }
  }
}


## Masters ##
output "masters_security_group_id" {
  value = module.master_nodes_sg.this_security_group_id
}


## Workers ##
output "workers_security_group_id" {
  value = module.worker_nodes_sg.this_security_group_id
}

output "workers_role_name" {
  value = length(var.workers) > 0 ? aws_iam_role.workers[0].name : ""
}

output "workers_role_arn" {
  value = length(var.workers) > 0 ? aws_iam_role.workers[0].arn : ""
}


## Route53 ##
output "route53_public_zone_id" {
  value = try(aws_route53_zone.public[0].id, null)

  depends_on = [
    aws_route53_record.ns
  ]
}

output "route53_public_zone_name" {
  value = try(aws_route53_zone.public[0].name, null)

  depends_on = [
    aws_route53_record.ns
  ]
}

output "route53_private_zone_id" {
  value = try(aws_route53_zone.private[0].id, null)

  depends_on = [
    aws_route53_record.ns
  ]
}

output "route53_private_zone_name" {
  value = try(aws_route53_zone.private[0].name, null)

  depends_on = [
    aws_route53_record.ns
  ]
}
