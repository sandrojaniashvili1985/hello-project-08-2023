output "vpc" {
  value = {
    vpc_id             = module.this.vpc_id
    availability_zones = module.this.availability_zones
    subnets            = {
      private = module.this.private_subnets
      public  = module.this.public_subnets
    }
    subnet_groups      = {
      database    = module.this.database_subnet_group_name
      elasticache = module.this.elasticache_subnet_group_name
    }
  }
}

output "name" {
  value = module.this.name
}

output "region" {
  value = module.this.region
}

output "vpc_id" {
  value = module.this.vpc_id
}

output "vpc_cidr" {
  value = module.this.vpc_cidr
}

output "secondary_cidr_blocks" {
  value = module.this.secondery_cidr_blocks
}

output "vpc_cidr_blocks" {
  value = sort(distinct(concat(
    [module.this.vpc_cidr],
    module.this.secondery_cidr_blocks
  )))
}

output "public_subnets" {
  value = module.this.public_subnets
}

output "public_subnets_per_az" {
  value = module.this.public_subnets_per_az
}

output "public_route_table_ids" {
  value = module.this.public_route_table_ids
}

output "private_subnets" {
  value = module.this.private_subnets
}

output "private_subnets_per_az" {
  value = module.this.private_subnets_per_az
}

output "private_route_table_ids" {
  value = module.this.private_route_table_ids
}

output "availability_zones" {
  value = module.this.availability_zones
}

output "bastion_security_group_id" {
  value = module.this.bastion_security_group_id
}

output "bastion_eip" {
  value = module.this.bastion_eip
}

output "bastion_user" {
  value = module.this.bastion_user
}

output "nat_public_ips" {
  value = module.this.nat_public_ips
}

output "database_subnet_group_name" {
  value = module.this.database_subnet_group_name
}

output "elasticache_subnet_group_name" {
  value = module.this.elasticache_subnet_group_name
}
