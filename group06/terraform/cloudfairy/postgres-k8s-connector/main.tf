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
      "${var.config.host_var_name}" = "${var.dependency.from_module.endpoints.primary.name}.${var.dependency.from_module.endpoints.primary.namespace}.svc.cluster.local:5432"
      "${var.config.user_var_name}" = var.dependency.from_module.endpoints.postgres_username
    }
    env_vars_secret_ref = {
      "${var.config.pass_var_name}" = var.dependency.from_module.env_var_secret_ref.postgres_password
    }
  }
}
