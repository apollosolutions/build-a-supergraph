resource "aws_iam_user" "eks_user" {
  name = "${var.demo_name}-eks-user"
}

resource "aws_iam_access_key" "eks_user_key" {
  user = aws_iam_user.eks_user.name
}

resource "aws_iam_user_policy" "eks_user_policy" {
  name = "eks-user-describe-policy"
  user = aws_iam_user.eks_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
      ]
      Resource = "*"
    }]
  })
}

resource "local_file" "eks_user_key_file" {
  content  = "AWS_ACCESS_KEY_ID=${aws_iam_access_key.eks_user_key.id}\nAWS_SECRET_ACCESS_KEY=${aws_iam_access_key.eks_user_key.secret}"
  filename = "eks_user_creds.txt"
}
