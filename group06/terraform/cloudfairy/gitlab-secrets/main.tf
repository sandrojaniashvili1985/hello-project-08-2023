## Variables ##
variable config {
  type = any
}

variable "dependency" {
  type = any
}

## Remote State ##
#data "terraform_remote_state" "admin" {
#  backend = "s3"
#  config  = {
#    bucket = "tikal-hackathon-terraform-state"
#    key    = "admin/gitlab"
#    region = "eu-west-1"
#  }
#}

data "aws_secretsmanager_secret" "secret" {
  name = var.config.name
}

## Secrets ##
data "aws_secretsmanager_secret_version" "secret" {
#  secret_id = data.terraform_remote_state.admin.outputs.group_secrets[var.config.name].id
  secret_id = data.aws_secretsmanager_secret.secret.id
}

output "cfout" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)
  sensitive = true
}

# Secrete Json format
# {
#   ssh = {
#     private = ""
#     public  = ""
#   }
#   gitlab = {
#     deploy_token = {
#       registry = "registry.gitlab.com"
#       username = ""
#       password = ""
#     }
#     sso = {
#       client_id     = ""
#       client_secret = ""
#     }
#   }
# }
