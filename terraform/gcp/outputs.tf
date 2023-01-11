output "kubernetes_cluster_names" {
  value = {
    for k, v in module.gke : k => v.name
  }
  description = "Cluster names for each stage"
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
