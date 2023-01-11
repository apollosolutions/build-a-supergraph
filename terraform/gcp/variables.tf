# Variables you're expected to set

variable "project_id" {
  description = "project id"
}

variable "github_token" {
  description = "github user token"
}

variable "apollo_key" {
  description = "Apollo key for checks, publishes, and Router Uplink"
}

variable "apollo_graph_id" {
  description = "Apollo graph ID for checks, publishes, and Router Uplink"
}

# Variables you can override if you know what you're doing

variable "demo_name" {
  default     = "apollo-supergraph-k8s"
  description = "name of the demo (used for K8s clusters, graphs, and github repos)"
  validation {
    condition     = length(var.demo_name) < 24
    error_message = "demo_name max length is 24"
  }
}

variable "project_region" {
  description = "project region"
  default     = "us-east1"
}

variable "demo_stages" {
  default = [
    {
      name : "dev",
      subnet_range : "10.10.0.0/16"
      ip_range_pods : "10.20.0.0/16",
      ip_range_services : "10.30.0.0/16",
      node_type : "e2-standard-2",
      min_nodes : 1,
      max_nodes : 1
    },
    {
      name : "prod",
      subnet_range : "10.40.0.0/16"
      ip_range_pods : "10.50.0.0/16",
      ip_range_services : "10.60.0.0/16",
      node_type : "e2-standard-2",
      min_nodes : 2,
      max_nodes : 3
    }
  ]
}

variable "subgraphs" {
  default = [
    {
      name : "subgraph-a",
      template_repo : {
        owner : "apollosolutions"
        repository : "build-a-supergraph-subgraph-a"
      }
    },
    {
      name : "subgraph-b",
      template_repo : {
        owner : "apollosolutions"
        repository : "build-a-supergraph-subgraph-b"
      }
    }
  ]
}
