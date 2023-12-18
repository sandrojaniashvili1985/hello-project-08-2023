variable config {
  type = any
}

variable "dependency" {
  type = any
}

output "cfout" {
  value = {
    type  = "connector"
    env_vars = {
      "${var.config.name}" = "${var.dependency.from_module.endpoints.mongodb.name}.${var.dependency.from_module.endpoints.mongodb.namespace}.svc.cluster.local:27017"
    }
  }
}
