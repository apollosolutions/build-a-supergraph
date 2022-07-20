output "kubernetes_cluster_names" {
  value = {
    for k, v in module.gke : k => v.name
  }
  description = "Cluster names"
}
