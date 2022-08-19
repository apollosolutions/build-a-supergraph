/**
  This file creates X number of VPCs set w/in ./variables.tf, which are used by the assigned clusters.
**/
module "gcp-network" {
  source = "terraform-google-modules/network/google"
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }
  project_id   = var.project_id
  network_name = "${var.demo_name}-${each.value.name}"
  subnets = [
    {
      subnet_name   = "${var.demo_name}-${each.value.name}"
      subnet_ip     = each.value.subnet_range
      subnet_region = var.project_region
    }
  ]
  secondary_ranges = {
    "${var.demo_name}-${each.value.name}" = [
      {
        ip_cidr_range = each.value.ip_range_pods
        range_name    = "${var.demo_name}-${each.value.name}-pods"
      },
      {
        ip_cidr_range = each.value.ip_range_services
        range_name    = "${var.demo_name}-${each.value.name}-services"
      }
    ]
  }
}

// peering to the dev infra network to be able to upload metric/traces/load testing
// tooling-infra <----> dev
resource "google_compute_network_peering" "tooling-infra-dev-peer" {
  name         = "${var.demo_name}-tooling-infra-dev-peer"
  network      = module.gcp-network["tooling-infra"].network_self_link
  peer_network = module.gcp-network["dev"].network_self_link
}
resource "google_compute_network_peering" "dev-tooling-infra-peer" {
  name         = "${var.demo_name}-dev-tooling-infra-peer"
  peer_network = module.gcp-network["tooling-infra"].network_self_link
  network      = module.gcp-network["dev"].network_self_link
}

// tooling-infra <----> prod
resource "google_compute_network_peering" "tooling-infra-prod-peer" {
  name         = "${var.demo_name}-tooling-infra-prod-peer"
  network      = module.gcp-network["tooling-infra"].network_self_link
  peer_network = module.gcp-network["prod"].network_self_link
}
resource "google_compute_network_peering" "prod-tooling-infra-peer" {
  name         = "${var.demo_name}-prod-tooling-infra-peer"
  peer_network = module.gcp-network["tooling-infra"].network_self_link
  network      = module.gcp-network["prod"].network_self_link
}
