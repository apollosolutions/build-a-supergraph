// Outputs the cluster names for each stage
output "kubernetes_cluster_names" {
  value = {
    for k, v in module.gke : k => v.name
  }
  description = "Cluster names"
}

output "repo_subgraph_a" {
  value       = github_repository.subgraph_repo_a.html_url
  description = "Subgraph A Repo"
}

output "repo_subgraph_b" {
  value       = github_repository.subgraph_repo_b.html_url
  description = "Subgraph B Repo"
}

output "repo_infra" {
  value       = github_repository.infra_repo.html_url
  description = "Infra (router, o11y) Repo"
}

output "load-balancer-ip" {
  value = module.gce-lb-http.external_ip
}
