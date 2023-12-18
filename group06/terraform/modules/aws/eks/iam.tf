## Master role ##
resource "aws_iam_role" "masters" {
  name               = "${var.name}-masters"
  assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT

  tags = merge(
    {
      Name = "${var.name}-masters"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "masters" {
  role       = aws_iam_role.masters.name
  policy_arn = aws_iam_policy.masters.arn
}

resource "aws_iam_role_policy_attachment" "masters_eks_cluster" {
  role       = aws_iam_role.masters.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "masters_eks_service" {
  role       = aws_iam_role.masters.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}


## Worker role ##
resource "aws_iam_role" "workers" {
  count = length(var.workers) > 0 ? 1 : 0

  name               = "${var.name}-workers"
  assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT

  tags = merge(
    {
      Name = "${var.name}-workers"
    },
    var.tags
  )
}

resource "aws_iam_instance_profile" "workers" {
  count = length(var.workers) > 0 ? 1 : 0

  name = "${var.name}-workers"
  role = aws_iam_role.workers[0].name
}

resource "aws_iam_role_policy_attachment" "workers" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = aws_iam_policy.workers[0].arn
}

resource "aws_iam_role_policy_attachment" "workers_external_dns" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = aws_iam_policy.external_dns_cert_manager.arn
}

resource "aws_iam_role_policy_attachment" "workers_cluster_autoscaler" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_iam_role_policy_attachment" "workers_eks_worker" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "workers_eks_ecr" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "workers_eks_cni" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "workers_ebs_csi_driver" {
  count = length(var.workers) > 0 ? 1 : 0

  role       = aws_iam_role.workers[0].name
  policy_arn = aws_iam_policy.aws_ebs_csi_driver.arn
}

resource "aws_iam_role_policy_attachment" "workers_extra" {
  for_each = var.workers_extra_iam_policies

  role       = aws_iam_role.workers[0].name
  policy_arn = aws_iam_policy.workers_extra[each.key].arn
}


## Policies ##
resource "aws_iam_policy" "masters" {
  name = "${var.name}-masters"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ecrRead",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbTagging",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbv2Describe",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbv2Create",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbv2ModifyDelete",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "elasticloadbalancing:ResourceTag/KubernetesCluster": "${var.name}",
          "elasticloadbalancing:ResourceTag/kubernetes.io/cluster/${var.name}": "owned"
        }
      }
    },
    {
      "Sid": "elbDescribe",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeLoadBalancerAttributes"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbCreate",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners"
      ],
      "Resource": "*"
    },
    {
      "Sid": "elbModifyDelete",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "elasticloadbalancing:ResourceTag/KubernetesCluster": "${var.name}",
          "elasticloadbalancing:ResourceTag/kubernetes.io/cluster/${var.name}": "owned"
        }
      }
    },
    {
      "Sid": "ec2Describe",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ec2Create",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:CreateRoute"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ec2ModifyDelete",
      "Effect": "Allow",
      "Action": [
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/KubernetesCluster": "${var.name}",
          "ec2:ResourceTag/kubernetes.io/cluster/${var.name}": "owned"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "workers" {
  count = length(var.workers) > 0 ? 1 : 0

  name = "${var.name}-workers"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ecrRead",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ec2Describe",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "workers_extra" {
  for_each = var.workers_extra_iam_policies

  name        = "${var.name}-${each.key}"
  description = each.value.description
  policy      = each.value.policy
}

resource "aws_iam_policy" "external_dns_cert_manager" {
  name = "${var.name}-external_dns-cert_manager"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.name}-cluster-autoscaler"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeInstanceTypes",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "ec2:DescribeLaunchTemplateVersions",
        "autoscaling:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "autoscaling:ResourceTag/KubernetesCluster": "${var.name}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "aws_ebs_csi_driver" {
  name = "${var.name}-aws-ebs-csi-driver"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
POLICY
}
