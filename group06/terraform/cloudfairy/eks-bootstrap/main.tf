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
}

data "aws_eks_cluster" "eks" {
  name = var.config.name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.config.name
}

## Variables ##
variable config {
  type = any
}

variable "dependency" {
  type = any
}


## Pull Secret ##
resource "kubernetes_secret" "gitlab_docker_pull" {
  metadata {
    name      = "gitlab-docker-pull"
    namespace = "default"
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.gitlab.com" = {
          auth = base64encode("${var.dependency.hackinfra_gitlab_secrets.gitlab.deploy_token.username}:${var.dependency.hackinfra_gitlab_secrets.gitlab.deploy_token.password}")
        }
      }
    })
  }
}

## Grafana ##
resource "kubernetes_namespace" "kube_prometheus_stack" {
  metadata {
    name = "kube-prometheus-stack"
  }
}

resource "kubernetes_secret" "grafana_gitlab" {
  metadata {
    name      = "grafana-gitlab"
    namespace = kubernetes_namespace.kube_prometheus_stack.id
  }
  type = "Opaque"
  data = {
    GITLAB_CLIENT_ID     = var.dependency.hackinfra_gitlab_secrets.gitlab.sso.client_id
    GITLAB_CLIENT_SECRET = var.dependency.hackinfra_gitlab_secrets.gitlab.sso.client_secret
  }
}

## ArgoCD ##
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret" "argocd" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace.argocd.id
  }
  type = "Opaque"
  data = {
    "ssh.private"        = var.dependency.hackinfra_gitlab_secrets.ssh.private
    "oidc.client.id"     = var.dependency.hackinfra_gitlab_secrets.gitlab.sso.client_id
    "oidc.client.secret" = var.dependency.hackinfra_gitlab_secrets.gitlab.sso.client_secret
  }

  lifecycle {
    ignore_changes = [
      data
    ]
  }
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "../../../argocd/releases/cluster-addons/argocd"

  dependency_update = true
}


## Output ##
output "cfout" {
  value = {
    cluster_name              = data.aws_eks_cluster.eks.name
    gitlab_docker_pull_secret = kubernetes_secret.gitlab_docker_pull.metadata[0].name
  }
}
