output "name" {
  value = var.name
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "secondery_cidr_blocks" {
  value = module.vpc.vpc_secondary_cidr_blocks
}

output "availability_zones" {
  value = var.availability_zones
}

output "public_subnets_cidr_blocks" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "public_subnets_per_az" {
  value = {
    for az in var.availability_zones:
      az => tolist(data.aws_subnet_ids.public_per_az[az].ids)
  }
}

output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "private_subnets_per_az" {
  value = {
    for az in var.availability_zones:
      az => tolist(data.aws_subnet_ids.private_per_az[az].ids)
  }
}

output "database_subnets" {
  value = module.vpc.private_subnets
}

output "database_subnet_group_name" {
  value = var.name
}

output "database_subnet_group_id" {
  value = module.vpc.database_subnet_group
}

output "elasticache_subnet_group_name" {
  value = module.vpc.elasticache_subnet_group_name
}

output "elasticache_subnet_group_id" {
  value = module.vpc.elasticache_subnet_group
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "nat_public_ips" {
  value = module.vpc.nat_public_ips
}

## Bastion ##
output "bastion_eip" {
  value = concat(aws_eip.bastion.*.public_ip, [""])[0]
}

output "bastion_user" {
  value = "ubuntu"
}

output "bastion_security_group_id" {
  value = module.bastion_sg.this_security_group_id
}

output "bastion_key_name" {
  value = concat(aws_key_pair.bastion.*.key_name, [""])[0]
}

output "bastion_key_id" {
  value = concat(aws_key_pair.bastion.*.id, [""])[0]
}
