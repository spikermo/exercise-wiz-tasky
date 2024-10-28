/*************************************************
*                   EKS CLUSTER                  *
*************************************************/

# Create the EKS IAM role
resource "aws_iam_role" "eks_iam_role" {
  name = "${var.project_prefix}-eks-iam-role"
  path = "/"

  assume_role_policy = <<EOF
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
EOF
}

# Attach the AmazonEKSClusterPolicy policy to the EKS IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  depends_on = [aws_iam_role.eks_iam_role]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}

# Attach the AmazonEKSServicePolicy policy to the EKS IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  depends_on = [aws_iam_role.eks_iam_role]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_iam_role.name
}

# Create the EKS worker nodes group role
resource "aws_iam_role" "workernodes" {
  depends_on = [aws_eks_cluster.eks]

  name = "${var.project_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach the AmazonEKSWorkerNodePolicy to the EKS worker nodes group role
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  depends_on = [aws_iam_role.workernodes]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

# Attach the AmazonEKS_CNI_Policy to the EKS worker nodes group role
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  depends_on = [aws_iam_role.workernodes]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

# Attach the EC2InstanceProfileForImageBuilderECRContainerBuilds to the EKS worker nodes group role
resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  depends_on = [aws_iam_role.workernodes]

  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

# Attach the AmazonEKS_CNI_Policy to the EKS worker nodes group role
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  depends_on = [aws_iam_role.workernodes]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

# Create the EKS Cluster
resource "aws_eks_cluster" "eks" {
  depends_on = [
    null_resource.create_cloudformation_stack,
    data.aws_subnet.public_subnet_1,
    data.aws_subnet.private_subnet_2
  ]

  name     = "${var.project_prefix}${var.cluster_label}"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [data.aws_subnet.public_subnet_1.id, data.aws_subnet.private_subnet_2.id]
  }
}

# Create the EKS worker node group
resource "aws_eks_node_group" "worker_node_group" {
  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role.workernodes,
    data.aws_subnet.public_subnet_1,
    data.aws_subnet.private_subnet_2
  ]

  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.project_prefix}-eks-worker-nodes"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [data.aws_subnet.public_subnet_1.id, data.aws_subnet.private_subnet_2.id]
  instance_types  = ["t3.xlarge"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "${var.project_prefix}-eks-node"
  }

  labels = {
    "Name" = "${var.project_prefix}-eks-node"
  }
}