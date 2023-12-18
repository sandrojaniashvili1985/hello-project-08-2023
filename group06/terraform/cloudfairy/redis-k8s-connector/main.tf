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
      "${var.config.name}" = "${var.dependency.from_module.endpoints.master.name}.${var.dependency.from_module.endpoints.master.namespace}.svc.cluster.local:6379"
    }
  }
}
