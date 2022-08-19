provider "github" {
  token = var.github_token
}

// repositories for k8s KRM/Terraform
resource "github_repository" "infra_repo" {
  name        = "${var.demo_name}-infrastructure"
  description = "Apollo K8s Supergraph infrastructure repository"
  visibility  = "private" # TODO make public
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-infra"
  }
}

resource "github_repository" "subgraph_repo_a" {
  name        = "${var.demo_name}-subgraph-a"
  description = "Apollo K8s Supergraph subgraph source code repository"
  visibility  = "private" # TODO make public
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-subgraph-a"
  }
}

resource "github_repository" "subgraph_repo_b" {
  name        = "${var.demo_name}-subgraph-b"
  description = "Apollo K8s Supergraph subgraph source code repository"
  visibility  = "private" # TODO make public
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-subgraph-b"
  }
}

// GH -> GKE Serivce Account and credentials
resource "google_service_account" "github-deploy-gsa" {
  project      = var.project_id
  account_id   = "github-deploy-gsa"
  display_name = "github-deploy-gsa"
}
resource "google_project_iam_binding" "github-deploy-binding" {
  project = var.project_id
  role    = "roles/container.developer"
  members = ["serviceAccount:${google_service_account.github-deploy-gsa.email}"]
}
resource "google_service_account_key" "github-deploy-key" {
  service_account_id = google_service_account.github-deploy-gsa.name
}
resource "local_file" "github-deploy-key" {
  content  = base64decode(google_service_account_key.github-deploy-key.private_key)
  filename = "${path.module}/github-deploy-key.json"
}

// GH Action Secrets
resource "github_actions_secret" "subgraph_a_action_secret" {
  repository      = github_repository.subgraph_repo_a.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}
resource "github_actions_secret" "subgraph_b_action_secret" {
  repository      = github_repository.subgraph_repo_b.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}
resource "github_actions_secret" "infra_action_secret" {
  repository      = github_repository.infra_repo.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}
