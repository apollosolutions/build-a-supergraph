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

resource "local_file" "kubeconfig" {
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }
  content  = module.gke_auth[each.key].kubeconfig_raw
  filename = "kubeconfig-${each.value.name}"
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
  kubernetes_version                = "1.23" # Bug w/ 1.24: https://github.com/hashicorp/terraform-provider-kubernetes/pull/1792

  network           = module.gcp-network[each.key].network_name
  subnetwork        = module.gcp-network[each.key].subnets_names[0]
  ip_range_pods     = "${var.demo_name}-${each.value.name}-pods"
  ip_range_services = "${var.demo_name}-${each.value.name}-services"
  node_pools = [
    {
      name         = "${each.value.name}-node-pool"
      machine_type = each.value.node_type
      min_count    = 1
      max_count    = var.gke_num_nodes
      disk_size_gb = 20
    },
  ]
  node_pools_tags = {
    all = ["gke-node", "${var.project_id}-gke"]
  }
}
