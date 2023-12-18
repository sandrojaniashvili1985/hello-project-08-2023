output "name" {
  value = module.this.name
}

output "route53" {
  value = {
    public  = module.this.route53_public_zone_id
    private = module.this.route53_private_zone_id
  }
}

output "workers_security_group_id" {
  value = module.this.workers_security_group_id
}

output "workers_role_name" {
  value = module.this.workers_role_name
}

output "workers_role_arn" {
  value = module.this.workers_role_arn
}

