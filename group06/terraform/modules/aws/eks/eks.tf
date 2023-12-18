resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = aws_iam_role.masters.arn
  version  = var.kubernetes_version

  vpc_config {
    security_group_ids      = [module.master_nodes_sg.this_security_group_id]
    subnet_ids              = var.private_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  tags = merge(
    {
      Name = var.name
    },
    local.cluster_tags,
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.masters_eks_cluster,
    aws_iam_role_policy_attachment.masters_eks_service,
    aws_iam_role_policy_attachment.masters,
    aws_cloudwatch_log_group.eks_logs
  ]
}

resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = 90

  tags = merge(
    {
      Name      = "/aws/eks/${var.name}/cluster"
      Cluster   = var.name
      Component = "Kubernetes Cluster"
    },
    local.cluster_tags,
    var.tags
  )
}


resource "kubernetes_config_map" "eks_aws_auth" {
  count = var.manage_aws_auth ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = replace(local.aws_auth, "\r\n", "\n")
  }

  depends_on = [
    aws_eks_cluster.cluster
  ]
}
