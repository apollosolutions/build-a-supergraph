# Create a VPC for each stage. The subnet names are used to create clusters in eks.tf.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }
  name = "${var.demo_name}-${each.value.name}-vpc"
  cidr = each.value.cidr

  private_subnets      = each.value.private_subnets
  public_subnets       = each.value.public_subnets
  azs                  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Terraform   = "true"
    Environment = each.key
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}
