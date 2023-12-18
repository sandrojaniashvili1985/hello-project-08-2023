## Locals ##
locals {
  eks_kube_config = <<EOT
apiVersion: v1
preferences: {}
kind: Config

clusters:
  - name: ${var.name}
    cluster:
      server: ${aws_eks_cluster.cluster.endpoint}
      certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority[0].data}

contexts:
  - name: ${var.name}
    context:
      cluster: ${var.name}
      user: ${var.name}

current-context: ${var.name}

users:
- name: ${var.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.name}"
EOT
}
