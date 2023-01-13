output "kubernetes_dev" {
  value       = module.eks_dev.cluster_name
  description = "Dev K8s Cluster"
}

output "kubernetes_prod" {
  value       = module.eks_prod.cluster_name
  description = "Prod K8s Cluster"
}

output "subgraph_repos" {
  value = {
    for k, v in github_repository.subgraph_repos : k => v.html_url
  }
  description = "Subgraph repo URLs"
}

output "repo_infra" {
  value       = github_repository.infra_repo.html_url
  description = "Infra (router, o11y) repo URLs"
}
