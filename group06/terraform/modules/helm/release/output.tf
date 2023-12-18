output "name" {
  value = var.name
}

output "manifest" {
  value = helm_release.this.manifest
}
