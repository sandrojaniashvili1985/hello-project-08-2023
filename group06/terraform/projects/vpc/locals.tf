locals {
  secrets = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)
}
