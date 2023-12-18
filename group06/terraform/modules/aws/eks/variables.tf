## Credentials ##
variable "public_key" {
  description = "RSA public key for EC2 key pair"
  type        = string
  default     = ""
}


## General ##
variable "name" {
  description = "Name of the cluster, this will be used to name all created resources"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy,"
  type        = string
  default     = ""
}


## Ingress ##
variable "load_balancers" {
  description = "Cluster load balancers, each item in the list will create a new Elastic Loadbalancer"
  type        = map(object({
    internal              = bool
    load_balancer_type    = string
    idle_timeout          = number
    main_ingress          = bool
    worker_names          = list(string)
    targets               = map(object({
      listener_port        = number
      listener_protocol    = string
      target_port          = number
      target_protocol      = string
      target_type          = string
      deregistration_delay = number
      proxy_protocol_v2    = bool
      stickiness           = map(string)
      acm_certificate_arns = list(string)
      default_action       = object({
        type   = string
        action = map(string)
      })
      health_check         = map(string)
    }))
    extra_security_groups = object({
      ingress_with_cidr_blocks              = list(object({
        description = string
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
      }))
      ingress_with_source_security_group_id = list(object({
        description              = string
        from_port                = number
        to_port                  = number
        protocol                 = string
        source_security_group_id = string
      }))
    })
    route53_records       = list(object({
      zone_id = string
      self    = bool
      records = list(string)
    }))
    tags                  = map(string)
  }))
  default = {}

  validation {
    condition     = !(length([for lb in keys(var.load_balancers): lb if var.load_balancers[lb].main_ingress]) > 1)
    error_message = "There must be no more then one main load balancer configured."
  }
}


## VPC ##
variable "vpc_id" {
  description = "VPC ID to deploy to"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Database subnet group name"
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "Availability zones names"
  type        = list(string)
}


## Route53 ##
variable "create_public_route53_zone" {
  description = "Enable/Disable creation of public Route53 zone"
  type        = bool
  default     = true
}

variable "create_private_route53_zone" {
  description = "Enable/Disable creation of private Route53 zone"
  type        = bool
  default     = true
}

variable "parent_route53_zone_id" {
  description = "Route53 zone ID of the parent domain"
  type        = string
  default     = ""
}

variable "additional_route53_associated_vpcs" {
  description = "Additional VPCs to associate with the cluster Route53 zone"
  type        = list(object({
    id     = string
    region = string
  }))
  default     = []
}


## Bastion ##
variable "bastion_ip" {
  description = "Bastion host IP used to connect to EC2 instances"
  type        = string
  default     = null
}

variable "bastion_user" {
  description = "Bastion host username"
  type        = string
  default     = null
}

variable "bastion_security_group_id" {
  description = "Used to allow SSH access from Bastion to all other instances"
  type        = string
  default     = null
}


## EKS ##
variable "manage_aws_auth" {
  description = "Enable to make TF manage aws-auth configmap, this requires running TF with network access to K8S API"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. When it's set to `false` ensure to have a proper private access with `cluster_endpoint_private_access = true`."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint. To use this `cluster_endpoint_private_access` and `cluster_create_endpoint_private_access_sg_rule` must be set to `true`."
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_private_access_sg" {
  description = "List of security group IDs which can access the Amazon EKS private API server endpoint. To use this `cluster_endpoint_private_access` and `cluster_create_endpoint_private_access_sg_rule` must be set to `true`."
  type        = list(string)
  default     = null
}

variable "masters_extra_security_rules" {
  description = "Master nodes configuration"
  type        = object({
    ingress_with_cidr_blocks              = list(map(string))
    ingress_with_source_security_group_id = list(map(string))
  })
  default     = {
    ingress_with_cidr_blocks              = []
    ingress_with_source_security_group_id = []
  }
}


## Workers ##
variable "workers" {
  description = "Cluster worker groups, each item in the list will create a new Auto Scaling Group"
  type        = map(object({
    subnets                = optional(list(string))
    instance_types         = optional(list(string))
    image_id               = optional(string)
    max_size               = optional(number)
    min_size               = optional(number)
    desired_capacity       = optional(number)
    enable_spot            = optional(bool)
    enable_autoscaling     = optional(bool)
    enabled_metrics        = optional(list(string))
    capacity_rebalance     = optional(bool)
    labels                 = optional(map(string))
    taints                 = optional(map(string))
    tags                   = optional(map(string))
    block_device_mappings  = optional(map(object({
      no_device             = optional(string)
      virtual_name          = optional(string)
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string)
    })))
    mixed_instances_policy = optional(object({
      on_demand_allocation_strategy            = optional(string)
      on_demand_base_capacity                  = optional(number)
      on_demand_percentage_above_base_capacity = optional(number)
      spot_allocation_strategy                 = optional(string)
      spot_instance_pools                      = optional(number)
      spot_max_price                           = optional(string)
    }))
  }))
  default = {}
}

variable "workers_defaults" {
  description = "Defaults for workers"
  type        = object({
    subnets                = optional(list(string))
    instance_types         = optional(list(string))
    image_id               = optional(string)
    max_size               = optional(number)
    min_size               = optional(number)
    desired_capacity       = optional(number)
    enable_spot            = optional(bool)
    enable_autoscaling     = optional(bool)
    enabled_metrics        = optional(list(string))
    capacity_rebalance     = optional(bool)
    labels                 = optional(map(string))
    taints                 = optional(map(string))
    tags                   = optional(map(string))
    block_device_mappings  = optional(map(object({
      no_device             = optional(string)
      virtual_name          = optional(string)
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string)
    })))
  })
  default = {}
}

variable "workers_extra_iam_policies" {
  description = "Additional IAM policies to create and attach to workers instance profile"
  type        = map(object({
    description = optional(string)
    policy      = string
  }))
  default     = {}
}

variable "workers_extra_security_rules" {
  description = "Additional security group rules to add to worker nodes"
  type        = object({
    ingress_with_cidr_blocks              = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    ingress_with_source_security_group_id = list(object({
      description              = string
      from_port                = number
      to_port                  = number
      protocol                 = string
      source_security_group_id = string
    }))
  })
  default     = {
    ingress_with_cidr_blocks              = []
    ingress_with_source_security_group_id = []
  }
}


## Tags ##
variable "tags" {
  description = "Tags to add to all created AWS resources"
  type        = map(string)
  default     = {}
}
