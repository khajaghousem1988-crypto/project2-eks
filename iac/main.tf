#####################################################
# Project 1 Shared Infrastructure State
#####################################################

data "terraform_remote_state" "project1" {
  backend = "s3"

  config = {
    bucket = var.project1_state_bucket
    key    = var.project1_state_key
    region = var.aws_region
  }
}

#####################################################
# Project 2 — EKS
#
# EKS resources will be added here in controlled
# phases. Project 1 resources are consumed as outputs
# only and are not recreated or moved.
#####################################################

locals {
  shared_vpc_id             = data.terraform_remote_state.project1.outputs.vpc_id
  shared_public_subnet_ids  = data.terraform_remote_state.project1.outputs.public_subnet_ids
  shared_private_subnet_ids = data.terraform_remote_state.project1.outputs.private_subnet_ids
}
#####################################################
# Project 2 — EKS Control Plane
#####################################################

module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  private_subnet_ids = local.shared_private_subnet_ids
}

#####################################################
# EKS Managed Node Group
#####################################################

module "eks_node_group" {
  source = "./modules/eks-node-group"

  project_name = var.project_name
  environment  = var.environment

  cluster_name       = module.eks.cluster_name
  private_subnet_ids = local.shared_private_subnet_ids

  instance_types = ["t3.micro"]

  desired_size = 3
  min_size     = 2
  max_size     = 3
}
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}