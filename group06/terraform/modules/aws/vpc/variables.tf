## General ##
variable "name" {
  description = "This will be used to name all created resources"
  type        = string
}

variable "region" {
  description = "Region to deploy to"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "secondary_cidr_blocks" {
  description = "Secondery VPC CIDR blocks"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "intra_subnets" {
  description = "Intra subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "elasticache_subnets" {
  description = "Elasticache subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "create_database_internet_gateway_route" {
  description = "Controls if an internet gateway route for public database access should be created"
  type        = bool
  default     = false
}

variable "create_database_subnet_route_table" {
  description = "Controls if separate route table for database should be created"
  type        = bool
  default     = false
}

## Bastion ##
variable "create_bastion" {
  description = "Whether to create a bastion EC2 instnace or not"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Bastion host EC2 public key"
  type        = string
  default     = ""
}

variable "bastion_ssh_cidr" {
  description = "CIDR allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


## Tags ##
variable "private_subnet_tags" {
  description = "Tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
