## Providers ##
terraform {
  required_providers {
    kubernetes = "~> 2.15.0"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }

  experiments {
    manifest = true
  }
}

## Data ##
data "aws_eks_cluster" "eks" {
  name = var.dependency.hackinfra_eks_bootstrap.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.dependency.hackinfra_eks_bootstrap.cluster_name
}

## Variables ##
variable config {
  type = any
}

variable "dependency" {
  type = any
}

## Release ##
resource "random_password" "postgres" {
  for_each = toset(["postgres-password", "password", "replication-password"])

  length = 32
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "${var.config.name}-creds"
    namespace = "default"
  }

  data = {
    postgres-password    = random_password.postgres["postgres-password"].result
    password             = random_password.postgres["password"].result
    replication-password = random_password.postgres["replication-password"].result
  }
}

module "this" {
  source = "../../modules/helm/release"

  name          = var.config.name
  namespace     = "default"
  repository    = "https://charts.bitnami.com/bitnami"
  chart         = "postgresql"
  chart_version = var.config.chart_version
  values        = [
    <<EOF
fullnameOverride: ${var.config.name}
global:
  imageRegistry: public.ecr.aws
  storageClass: gp3
  postgresql:
    auth:
      existingSecret: ${kubernetes_secret.postgres.metadata[0].name}
      secretKeys:
        adminPasswordKey: postgres-password
        userPasswordKey: password
        replicationPasswordKey: replication-password
image:
  tag: 15.1.0-debian-11-r1
readReplicas:
  replicaCount: 1
EOF
  ]
}

locals {
  manifest = jsondecode(module.this.manifest)
}

## Output ##
output "cfout" {
  value = {
    endpoints = {
      primary           = local.manifest["default/service/v1/${var.config.name}"].metadata
      postgres_username = "postgres"
    }
    env_var_secret_ref = {
      postgres_password = {
        name = kubernetes_secret.postgres.metadata[0].name
        key  = "postgres-password"
      }
    }
  }
}
