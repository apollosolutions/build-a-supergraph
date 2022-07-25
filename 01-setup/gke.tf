module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  for_each     = var.demo_stages
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke[each.key].location
  cluster_name = module.gke[each.key].name
}

resource "local_file" "kubeconfig" {
  for_each = var.demo_stages
  content  = module.gke_auth[each.key].kubeconfig_raw
  filename = "kubeconfig-${each.key}"
}

module "gke" {
  source   = "terraform-google-modules/kubernetes-engine/google"
  for_each = var.demo_stages

  project_id                        = var.project_id
  name                              = "${var.demo_name}-${each.value}"
  regional                          = true
  region                            = var.project_region
  disable_legacy_metadata_endpoints = true

  network           = module.gcp-network[each.key].network_name
  subnetwork        = module.gcp-network[each.key].subnets_names[0]
  ip_range_pods     = ""
  ip_range_services = ""
  node_pools = [
    {
      name         = "${each.value}-node-pool"
      machine_type = var.gke_node_type
      min_count    = 1
      max_count    = var.gke_num_nodes
      disk_size_gb = 20
    },
  ]
  node_pools_tags = {
    all = ["gke-node", "${var.project_id}-gke"]
  }
}
