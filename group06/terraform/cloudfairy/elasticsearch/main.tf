## Helm ##
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
module "this" {
  source = "../../modules/helm/release"

  name          = var.config.name
  namespace     = "default"
  repository    = "https://charts.bitnami.com/bitnami"
  chart         = "elasticsearch"
  chart_version = var.config.chart_version
  values        = [
    <<EOF
fullnameOverride: ${var.config.name}
global:
  imageRegistry: public.ecr.aws
  storageClass: gp3
  kibanaEnabled: true
extraConfig:
  xpack.security.enabled: false
  xpack.security.http.ssl.enabled: false
  xpack.security.transport.ssl.enabled: false
  xpack.security.authc:
    anonymous:
      username: anonymous
      roles: superuser
      authz_exception: true
ingress:
  enabled: true
  pathType: ImplementationSpecific
  hostname: elasticsearch.group07.hack22.tikalk.dev
  path: /
  ingressClassName: nginx
  extraTls:
    - hosts:
        - elasticsearch.group07.hack22.tikalk.dev
kibana:
  ingress:
    enabled: true
    ingressClassName: nginx
    hostname: kibana.group07.hack22.tikalk.dev
    extraTls:
      - hosts:
          - elasticsearch.group07.hack22.tikalk.dev
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
      elasticsearch = local.manifest["default/service/v1/${var.config.name}"].metadata
    }
  }
}
