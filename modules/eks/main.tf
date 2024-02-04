
# Create EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.iamrole.arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
    # aws_subnet.public[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.ekspolicy,
    aws_iam_role_policy_attachment.eksrc,
  ]
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iamrole" {
  name               = "eks-cluster-iamrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ekspolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iamrole.name
}

resource "aws_iam_role_policy_attachment" "eksrc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iamrole.name
}

# # Create EKS Node Group
# resource "aws_eks_node_group" "nodegp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "node-group"
#   node_role_arn   = aws_iam_role.eks_node_role.arn

#   subnet_ids      = var.public_subnet_ids
#   instance_types  = ["t2.medium"]
#   capacity_type   = "SPOT"
#   scaling_config {
#     desired_size = 1
#     max_size     = 3
#     min_size     = 1
#   }
# }

# # Define IAM Role for EKS Node Group
# resource "aws_iam_role" "eks_node_role" {
#   name               = "eks-node-role"
#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [{
#       Effect    = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com",
#       },
#       Action    = "sts:AssumeRole",
#     }],
#   })
# }

# # Define IAM Policy for EKS Node Group
# resource "aws_iam_policy" "eks_node_policy" {
#   name        = "eks-node-policy"
#   description = "Policy for EKS node group"
#   policy      = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect   = "Allow",
#       Action   = [
#         "eks:DescribeNodegroup",
#         "eks:ListNodegroups",
#         "eks:DescribeCluster",
#         "eks:ListClusters",
#       ],
#       Resource = "*",
#     }],
#   })
# }

# # Attach IAM Policy to IAM Role
# resource "aws_iam_policy_attachment" "eks_node_policy_attachment" {
#   name       = "eks-node-policy-attachment"
#   roles      = [aws_iam_role.eks_node_role.name]
#   policy_arn = aws_iam_policy.eks_node_policy.arn
# }