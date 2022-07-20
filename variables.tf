variable "project_id" {
  description = "project id"
}

variable "project_region" {
  description = "project region"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "gke_node_type" {
  default     = "e2-standard-2"
  description = "machine type of gke nodes"
}

variable "demo_name" {
  default     = "apollo-supergraph-k8s"
  description = "name of the demo (used for resources)"
}

variable "demo_stages" {
  type = set(string)
  default = [
    "dev",
    "prod"
  ]
}
