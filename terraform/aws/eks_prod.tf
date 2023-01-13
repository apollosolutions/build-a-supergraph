provider "kubernetes" {
  alias                  = "prod"
  host                   = module.eks_prod.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_prod.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks_prod.cluster_name]
  }
}

module "eks_prod" {
  source = "terraform-aws-modules/eks/aws"
  providers = {
    kubernetes = kubernetes.prod
  }
  cluster_name                   = "${var.demo_name}-prod"
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc["prod"].vpc_id
  subnet_ids               = module.vpc["prod"].private_subnets
  control_plane_subnet_ids = module.vpc["prod"].intra_subnets

  manage_aws_auth_configmap = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["${var.demo_stages["prod"].node_type}"]
  }

  eks_managed_node_groups = {
    primary = {
      disk_size    = 20
      min_size     = var.demo_stages["prod"].min_nodes
      max_size     = var.demo_stages["prod"].max_nodes
      desired_size = var.demo_stages["prod"].min_nodes

      instance_types = ["${var.demo_stages["prod"].node_type}"]
    }
  }

  create_iam_role          = true
  iam_role_name            = "${substr(var.demo_name, 0, 12)}-prod-eks-deploy"
  iam_role_use_name_prefix = false
  aws_auth_users = [
    {
      userarn  = aws_iam_user.eks_user.arn
      username = aws_iam_user.eks_user.name
      groups   = ["system:masters"]
    }
  ]
}
