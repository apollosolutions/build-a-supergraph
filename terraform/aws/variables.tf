# Variables you're expected to set
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
  default     = "us-east-1"
}

# TODO: Update node_type to m6g (Graviton) once ARM64 support lands in each subgraph repo
variable "demo_stages" {
  type = map(any)
  default = {
    dev = {
      name : "dev",
      cidr : "10.0.0.0/16",
      private_subnets : ["10.0.0.0/20", "10.0.16.0/20"],
      public_subnets : ["10.0.32.0/20", "10.0.48.0/20"],
      node_type : "m6a.large",
      min_nodes : 1,
      max_nodes : 1
    },
    # prod={
    #   name : "prod",
    #   cidr : "10.1.0.0/16",
    #   private_subnets : ["10.1.0.0/20", "10.1.16.0/20"],
    #   public_subnets : ["10.1.32.0/20", "10.1.48.0/20"],
    #   node_type : "m6a.large",
    #   min_nodes : 2,
    #   max_nodes : 3
    # }
  }
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
