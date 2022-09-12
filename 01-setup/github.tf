provider "github" {
  token = var.github_token
}

// repositories for k8s KRM/Terraform
resource "github_repository" "infra_repo" {
  name        = "${var.demo_name}-infra"
  description = "Apollo K8s Supergraph infrastructure repository"
  visibility  = "public"
  depends_on = [
    module.gke
  ]
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-infra"
  }
}

resource "github_repository" "subgraph_repo_a" {
  name        = "${var.demo_name}-subgraph-a"
  description = "Apollo K8s Supergraph subgraph source code repository"
  visibility  = "public"
  depends_on = [
    module.gke
  ]
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-subgraph-a"
  }
}

resource "github_repository" "subgraph_repo_b" {
  name        = "${var.demo_name}-subgraph-b"
  description = "Apollo K8s Supergraph subgraph source code repository"
  visibility  = "public"
  depends_on = [
    module.gke
  ]
  template {
    owner      = "apollosolutions"
    repository = "build-a-supergraph-subgraph-b"
  }
}

// GH -> GKE Serivce Accounts and credentials
// Deployer credentials for subgraph repos
resource "google_service_account" "github-deploy-gsa" {
  project      = var.project_id
  account_id   = "${substr(var.demo_name, 0, 12)}-github-deploy-gsa"
  display_name = "${substr(var.demo_name, 0, 12)}-github-deploy-gsa"
}
resource "google_project_iam_member" "github-deploy-developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github-deploy-gsa.email}"
}
resource "google_project_iam_member" "github-deploy-viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.github-deploy-gsa.email}"
}
resource "google_service_account_key" "github-deploy-key" {
  service_account_id = google_service_account.github-deploy-gsa.name
}
resource "local_file" "github-deploy-key" {
  content  = base64decode(google_service_account_key.github-deploy-key.private_key)
  filename = "${path.module}/github-deploy-key.json"
}

// Service Admin credentials for infra repo (so it can manage more resources like cluster roles)
resource "google_service_account" "github-manage-gsa" {
  project      = var.project_id
  account_id   = "${substr(var.demo_name, 0, 12)}-github-manage-gsa"
  display_name = "${substr(var.demo_name, 0, 12)}-github-manage-gsa"
}
resource "google_project_iam_member" "github-manage-admin" {
  project = var.project_id
  role    = "roles/container.serviceAdmin"
  member  = "serviceAccount:${google_service_account.github-manage-gsa.email}"
}
resource "google_service_account_key" "github-manage-key" {
  service_account_id = google_service_account.github-manage-gsa.name
}
resource "local_file" "github-manage-key" {
  content  = base64decode(google_service_account_key.github-manage-key.private_key)
  filename = "${path.module}/github-manage-key.json"
}

// GH Action Secrets
// subgraph a
resource "github_actions_secret" "subgraph_a_apollo_graph_secret" {
  repository      = github_repository.subgraph_repo_a.name
  secret_name     = "APOLLO_GRAPH_ID"
  plaintext_value = var.apollo_graph_id
}
resource "github_actions_secret" "subgraph_a_apollo_secret" {
  repository      = github_repository.subgraph_repo_a.name
  secret_name     = "APOLLO_KEY"
  plaintext_value = var.apollo_key
}
resource "github_actions_secret" "subgraph_a_cluster_prefix" {
  repository      = github_repository.subgraph_repo_a.name
  secret_name     = "CLUSTER_PREFIX"
  plaintext_value = var.demo_name
}
resource "github_actions_secret" "subgraph_a_gcp_secret" {
  repository      = github_repository.subgraph_repo_a.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}

// subgraph b
resource "github_actions_secret" "subgraph_b_apollo_graph_secret" {
  repository      = github_repository.subgraph_repo_b.name
  secret_name     = "APOLLO_GRAPH_ID"
  plaintext_value = var.apollo_graph_id
}
resource "github_actions_secret" "subgraph_b_apollo_secret" {
  repository      = github_repository.subgraph_repo_b.name
  secret_name     = "APOLLO_KEY"
  plaintext_value = var.apollo_key
}
resource "github_actions_secret" "subgraph_b_cluster_prefix" {
  repository      = github_repository.subgraph_repo_b.name
  secret_name     = "CLUSTER_PREFIX"
  plaintext_value = var.demo_name
}
resource "github_actions_secret" "subgraph_b_gcp_secret" {
  repository      = github_repository.subgraph_repo_b.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}

// infra
resource "github_actions_secret" "infra_apollo_graph_secret" {
  repository      = github_repository.infra_repo.name
  secret_name     = "APOLLO_GRAPH_ID"
  plaintext_value = var.apollo_graph_id
}
resource "github_actions_secret" "infra_apollo_key_resource_name" {
  repository      = github_repository.infra_repo.name
  secret_name     = "APOLLO_KEY_RESOURCE_NAME"
  plaintext_value = google_secret_manager_secret_version.apollo-key-version.name
}
resource "github_actions_secret" "infra_cluster_prefix" {
  repository      = github_repository.infra_repo.name
  secret_name     = "CLUSTER_PREFIX"
  plaintext_value = var.demo_name
}
resource "github_actions_secret" "infra_gcp_secret" {
  repository      = github_repository.infra_repo.name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-manage-key.private_key)
}
