terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    github = {
      source = "integrations/github"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.project_region
}
