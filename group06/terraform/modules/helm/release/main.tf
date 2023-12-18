resource "helm_release" "this" {
  name          = var.name
  namespace     = var.namespace
  chart         = var.chart
  repository    = var.repository
  version       = var.chart_version
  values        = var.values
  wait          = var.wait
  wait_for_jobs = var.wait

  dynamic "set" {
    for_each = {for x in var.set:
      x.name => {
        name  = x.name
        value = x.value
      }
    }
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  dynamic "set_sensitive" {
    for_each = {for x in var.set:
      x.name => {
        name  = x.name
        value = x.value
      }
    }
    content {
      name  = set_sensitive.value.name
      value = set_sensitive.value.value
    }
  }
}
