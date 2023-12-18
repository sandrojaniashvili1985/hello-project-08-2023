## Remote State ##
data "terraform_remote_state" "admin" {
  backend = "s3"
  config  = {
    bucket = "tikal-hackathon-terraform-state"
    key    = "admin/gitlab"
    region = "eu-west-1"
  }
}

## Secrets ##
data "aws_secretsmanager_secret_version" "secret" {
  secret_id = data.terraform_remote_state.admin.outputs.group_secrets[var.name].id
}
