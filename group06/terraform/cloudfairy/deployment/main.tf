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
variable "config" {
  type = any
}

variable "dependency" {
  type = any
}

variable "connector" {
  type = any
}

## Local ##
locals {
  manifest = jsondecode(module.this.manifest)

  env_var_connectors_keys   = flatten(concat([for provider in var.connector:
    [for connector in provider:
      [for key, value in lookup(connector, "env_vars", {}):
        key
      ]
    ]
  ]))
  env_var_connectors_values = flatten(concat([for provider in var.connector:
    [for connector in provider:
      [for key, value in lookup(connector, "env_vars", []):
        value
      ]
    ]
  ]))
  env_var_connectors_data   = zipmap(local.env_var_connectors_keys, local.env_var_connectors_values)
}

## Release ##
resource "kubernetes_config_map" "env_var_connectors" {
  metadata {
    name      = "${var.config.name}-cf-connector"
    namespace = "default"
  }

  lifecycle {
    ignore_changes = [data]
  }
}

resource "kubernetes_config_map_v1_data" "env_var_connectors" {
  for_each = local.env_var_connectors_data

  metadata {
    name      = kubernetes_config_map.env_var_connectors.metadata[0].name
    namespace = kubernetes_config_map.env_var_connectors.metadata[0].namespace
  }

  field_manager = "Terraform - ${each.key}"
  data          = {
   "${each.key}" = each.value
  }
}

module "this" {
  source = "../../modules/helm/release"

  name          = var.config.name
  namespace     = "default"
  chart         = "../../../helm-charts/workload"
  values        = [
    <<EOF
fullnameOverride: ${var.config.name}
replicaCount: ${var.config.replicas}
image:
  repository: ${var.config.name}
  pullPolicy: Always
  tag: latest
imagePullSecrets:
  - name: ${var.dependency.hackinfra_eks_bootstrap.gitlab_docker_pull_secret}
ports:
  http:
    containerPort: ${var.config.port}
    protocol: TCP
service:
  enabled: true
  type: ClusterIP
  ports:
    http:
      port: ${var.config.port}
      targetPort: http
      protocol: TCP
ingress:
  enabled: ${var.config.ingress}
  ingressClassName: nginx
  hosts:
    ${var.config.name}.${var.config.domain}:
      - path: /
        service:
          port:
            name: http
  tls:
    - hosts:
        - ${var.config.name}.${var.config.domain}
extraEnvFrom:
  - configMapRef:
      name: ${kubernetes_config_map.env_var_connectors.metadata[0].name}
extraEnv:
%{ for provider in var.connector ~}
%{ for connector in provider ~}
%{ for name, config in lookup(connector, "env_vars_secret_ref", {}) ~}
  - name: ${name}
    valueFrom:
      secretKeyRef:
        name: ${config.name}
        key: ${config.key}
%{ endfor ~}
%{ endfor ~}
%{ endfor ~}
EOF
  ]
}

## Output ##
output "cfout" {
  value = {
    endpoints = {
      endpoint = format("%s:%s", local.manifest["service/v1/${var.config.name}"].metadata.name, var.config.port)
    }
  }
}
