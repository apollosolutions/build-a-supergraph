output "kubernetes_cluster_names" {
  value = {
    for k, v in module.gke : k => v.name
  }
  description = "Cluster names"
}

output "load-balancer-ip" {
  value = module.gce-lb-http.external_ip
}