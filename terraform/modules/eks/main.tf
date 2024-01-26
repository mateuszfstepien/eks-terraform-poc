resource "aws_eks_cluster" "sandboxing" {
  name     = var.cluster_name
  role_arn = aws_iam_role.sandboxing_cluster.arn

  vpc_config {
    subnet_ids              = var.aws_public_subnet
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.sandboxing_ng.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.sandboxing-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.sandboxing-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "sandboxing" {
  cluster_name    = aws_eks_cluster.sandboxing.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.sandboxing_ng.arn
  subnet_ids      = var.aws_public_subnet
  instance_types  = var.instance_types

  remote_access {
    source_security_group_ids = var.restrict_ssh_node_access ? [aws_security_group.sandboxing_ng.id] : null
    ec2_ssh_key               = var.key_pair
  }

  scaling_config {
    desired_size = var.scaling_desired_size
    max_size     = var.scaling_max_size
    min_size     = var.scaling_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.sandboxing-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.sandboxing-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.sandboxing-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_security_group" "sandboxing_ng" {
  name_prefix = "sandboxing_ng"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "sandboxing_cluster" {
  name = "eks-cluster-sandboxing"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_role_policy_attachment" "sandboxing-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.sandboxing_cluster.name
}

resource "aws_iam_role_policy_attachment" "sandboxing-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.sandboxing_cluster.name
}

resource "aws_iam_role" "sandboxing_ng" {
  name = "eks-node-group-sandboxing"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "sandboxing-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.sandboxing_ng.name
}

resource "aws_iam_role_policy_attachment" "sandboxing-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.sandboxing_ng.name
}

resource "aws_iam_role_policy_attachment" "sandboxing-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.sandboxing_ng.name
}


