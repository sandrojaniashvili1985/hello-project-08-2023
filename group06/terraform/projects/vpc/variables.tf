variable "name" {
  type    = string
  default = "group07"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
