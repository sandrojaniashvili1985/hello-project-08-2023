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
          auth = base64encode("${local.secrets["gitlab"]["deploy_token"]["username"]}:${local.secrets["gitlab"]["deploy_token"]["password"]}")
        }
      }
    })
  }
}

## ArgoCD
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
    "ssh.private"   = local.secrets["ssh"]["private"]
    "oidc.client.id"     = local.secrets["gitlab"]["sso"]["client_id"]
    "oidc.client.secret" = local.secrets["gitlab"]["sso"]["client_secret"]
  }

  lifecycle {
    ignore_changes = [
      data
    ]
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
    GITLAB_CLIENT_ID     = local.secrets["gitlab"]["sso"]["client_id"]
    GITLAB_CLIENT_SECRET = local.secrets["gitlab"]["sso"]["client_secret"]
  }
}
