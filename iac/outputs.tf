output "shared_vpc_id" {
  value = local.shared_vpc_id
}

output "shared_public_subnet_ids" {
  value = local.shared_public_subnet_ids
}

output "shared_private_subnet_ids" {
  value = local.shared_private_subnet_ids
}
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}
output "eks_node_group_name" {
  value = module.eks_node_group.node_group_name
}

output "eks_node_role_arn" {
  value = module.eks_node_group.node_role_arn
}
output "ecr_repository_url" {
  description = "Project 2 ECR repository URL"
  value       = module.ecr.repository_url
}