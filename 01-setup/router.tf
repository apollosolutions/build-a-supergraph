resource "google_compute_instance_group_named_port" "router" {
  for_each = {
    for index, stage in var.demo_stages : stage.name => stage
  }
  
  group = "google_container_cluster.${var.demo_name}-${each.value.name}.node_pool[0].instance_group_urls[0]"
  zone = var.project_region

  name = var.router_port_name
  port = var.router_port
}