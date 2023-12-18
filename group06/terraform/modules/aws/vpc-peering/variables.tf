## Requester ##
variable "requester_vpc_id" {
  description = "Requester VPC ID"
  type        = string
}

variable "requester_route_table_ids" {
  description = "Requester route table IDs"
  type        = list(string)
}


## Accepter ##
variable "accepter_vpc_id" {
  description = "Accepter VPC ID"
  type        = string
}

variable "accepter_route_table_ids" {
  description = "Accepter route table IDS"
  type        = list(string)
}

variable "accepter_region" {
  description = "Accepter region"
  type        = string
}


## Tags ##
variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
