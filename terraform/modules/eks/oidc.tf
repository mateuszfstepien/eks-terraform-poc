/*
data "tls_certificate" "tls" {
  url = aws_eks_cluster.sandboxing.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "sandboxing" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tls.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.tls.url

}
data "aws_iam_policy_document" "sandboxing_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.sandboxing.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.sandboxing.arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_role" "aws-node" {
  assume_role_policy = data.aws_iam_policy_document.sandboxing_assume_role_policy.json
  name               = "aws-node"
}
resource "aws_eks_identity_provider_config" "sandboxing" {
  cluster_name = aws_eks_cluster.sandboxing.name
  oidc {
    client_id                     = substr(data.tls_certificate.tls.url, -32, -1)
    identity_provider_config_name = "sandboxing"
    issuer_url                    = "https://${aws_iam_openid_connect_provider.sandboxing.url}"

  }
}

### CSI driver

resource "aws_iam_policy" "eks_cluster_ebs_csi_iam_policy" {
  name        = "${aws_eks_cluster.sandboxing.name}-ebs-csi-policy"
  path        = "/"
  description = "EBS CSI IAM Policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
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
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/kubernetes.io/created-for/pvc/name" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      }
    ]
  })
}


output "eks_cluster_ebs_csi_iam_policy_arn" {
  value = aws_iam_policy.eks_cluster_ebs_csi_iam_policy.arn
}

data "aws_iam_policy_document" "eks_cluster_ebs_csi_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.sandboxing.arn]
    }
    condition {
      test = "StringEquals"
      #variable = "${element(split("oidc-provider/", "${aws_iam_openid_connect_provider.sandboxing.arn}"), 1)}:sub"
      variable = "${replace(aws_iam_openid_connect_provider.sandboxing.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-ebs-csi-controller-sa"]
    }
  }
  version = "2012-10-17"
}


### Associate role with the Policy eks_cluster_ebs_csi_policy
resource "aws_iam_role" "eks_cluster_ebs_csi_role" {
  name               = "${aws_eks_cluster.sandboxing.name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_ebs_csi_policy.json
}

# Associate EBS CSI IAM Policy to EBS CSI IAM Role
resource "aws_iam_role_policy_attachment" "eks_cluster_ebs_csi_role_policy_attach" {
  # policy_arn = aws_iam_policy.eks_cluster_ebs_csi_iam_policy.arn
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_cluster_ebs_csi_role.name
}

output "ebs_csi_iam_role_arn" {
  description = "EBS CSI IAM Role ARN"
  value       = aws_iam_role.eks_cluster_ebs_csi_role.arn
}

resource "aws_eks_addon" "eks_cluster_ebs_csi_addon" {
  cluster_name             = aws_eks_cluster.sandboxing.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.25.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_cluster_ebs_csi_role.arn
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_ebs_csi_role_policy_attach,
    aws_iam_role.eks_cluster_ebs_csi_role
  ]

}
output "eks_cluster_ebs_addon_arn" {
  description = "Amazon Resource Name (ARN) of the EKS add-on"
  value       = aws_eks_addon.eks_cluster_ebs_csi_addon.arn
}
output "eks_cluster_ebs_addon_id" {
  description = "EKS Cluster name and EKS Addon name"
  value       = aws_eks_addon.eks_cluster_ebs_csi_addon.id
}
output "eks_cluster_ebs_addon_time" {
  description = "Date and time in RFC3339 format that the EKS add-on was created"
  value       = aws_eks_addon.eks_cluster_ebs_csi_addon.created_at
}
*/

data "tls_certificate" "sandboxing" {
  url = aws_eks_cluster.sandboxing.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "sandboxing" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.sandboxing.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.sandboxing.url
}

data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.sandboxing.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.sandboxing.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.csi.json
  name               = "eks-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role       = aws_iam_role.eks_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.sandboxing.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.25.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn
}
