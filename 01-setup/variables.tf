variable "demo_name" {
  default     = "apollo-supergraph-k8s"
  description = "name of the demo (used for resources)"
}

variable "project_id" {
  description = "project id"
}

variable "github_token" {
  description = "github user token"
}

variable "github_username" {
  description = "github user token"
}

variable "github_email" {
  description = "github user token"
}

variable "project_region" {
  description = "project region"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "router_port" {
  default = 80
  description = "Apollo Router service NodePort port number"
}

variable "router_port_name" {
  default = "http"
  description = "Apollo Router service NodePort port name"
}

// adding in IP info here to make it easier to manage.
// due to the peering needed to support a shared tooling-infra cluster (for uploading metrics), each subnet cannot conflict; giving each range a healthy /16 avoids potential
// IP exhaustion for the demo.
variable "demo_stages" {
  default = [
    {
      name : "tooling-infra",
      subnet_range : "10.10.0.0/16"
      ip_range_pods : "10.20.0.0/16",
      ip_range_services : "10.30.0.0/16",
      node_type : "e2-standard-2"
    },
    {
      name : "prod",
      subnet_range : "10.40.0.0/16"
      ip_range_pods : "10.50.0.0/16",
      ip_range_services : "10.60.0.0/16",
      node_type : "e2-standard-2"
    },
    {
      name : "dev",
      subnet_range : "10.70.0.0/16"
      ip_range_pods : "10.80.0.0/16",
      ip_range_services : "10.90.0.0/16",
      node_type : "e2-standard-2"
    }
  ]
}

// apollo-specific variables used for secrets
variable "apollo_key" {
  description = "Apollo key for Router"
}
