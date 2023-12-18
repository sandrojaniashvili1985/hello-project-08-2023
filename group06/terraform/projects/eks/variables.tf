variable "name" {
  description = "Cluster name"
  type        = string
  default     = "group07"
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "hackit.tikalk.dev"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
