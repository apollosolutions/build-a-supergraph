# For each stage in `var.demo_stages`, create a Kubernetes cluster.
#
# The clusters a generally configured the same. The subnet IP ranges, node
# instance type, and node counts are configurable per cluster.
#
# The clusters are named `{demo_name}-{stage}`, e.g. "apollo-supergraph-k8s-dev".
module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke[each.key].location
  cluster_name = module.gke[each.key].name
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }

  project_id                        = var.project_id
  name                              = "${var.demo_name}-${each.value.name}"
  regional                          = true
  region                            = var.project_region
  disable_legacy_metadata_endpoints = true

  network           = module.gcp-network[each.key].network_name
  subnetwork        = module.gcp-network[each.key].subnets_names[0]
  ip_range_pods     = "${var.demo_name}-${each.value.name}-pods"
  ip_range_services = "${var.demo_name}-${each.value.name}-services"
  node_pools = [
    {
      name         = "${each.value.name}-node-pool"
      machine_type = each.value.node_type
      min_count    = each.value.min_nodes
      max_count    = each.value.max_nodes
      disk_size_gb = 20
    },
  ]
  node_pools_tags = {
    all = ["gke-node", "${var.project_id}-gke"]
  }
}
