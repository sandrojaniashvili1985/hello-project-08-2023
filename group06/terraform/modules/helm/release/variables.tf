variable "name" {
  description = "Release Name"
  type        = string
}

variable "namespace" {
  description = "The namespace to install the release into. Defaults to 'default'"
  type        = string
}

variable "chart" {
  description = "Chart name to be installed, for local chart provide the path"
  type        = string
}

variable "repository" {
  description = "Repository URL where to locate the requested chart"
  type        = string
  default     = ""
}

variable "chart_version" {
  description = "Specify the exact chart version to install. If this is not specified, the latest version is installed"
  type        = string
  default     = ""
}

variable "wait" {
  description = "Wait till all resources & jobs are ready"
  type        = bool
  default     = false
}

variable "values" {
  description = "Values in raw yaml to pass to helm"
  type        = list(string)
  default     = []
}

variable "set" {
  description = "Set values"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "set_sensitive" {
  description = "Set ensitive values"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}
