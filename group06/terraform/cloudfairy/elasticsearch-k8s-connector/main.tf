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
      "${var.config.name}" = "${var.dependency.from_module.endpoints.elasticsearch.name}.${var.dependency.from_module.endpoints.elasticsearch.namespace}.svc.cluster.local:9200"
    }
  }
}
