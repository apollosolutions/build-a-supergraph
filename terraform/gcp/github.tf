provider "github" {
  token = var.github_token
}

# Infra repo for Router, Otel, load testing
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

# Repo for subgraphs
resource "github_repository" "subgraph_repos" {
  for_each = {
    for index, subgraph in var.subgraphs : subgraph.name => subgraph
  }

  name        = "${var.demo_name}-${each.value.name}"
  description = "Apollo K8s Supergraph ${each.value.name} source code repository"
  visibility  = "public"
  depends_on = [
    module.gke
  ]
  template {
    owner      = each.value.template_repo.owner
    repository = each.value.template_repo.repository
  }
}

### Github -> GKE Serivce Accounts and credentials ###

# "Deployer" credentials for subgraph repos
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
resource "google_service_account_key" "github-deploy-key" {
  service_account_id = google_service_account.github-deploy-gsa.name
}
resource "local_file" "github-deploy-key" {
  content  = base64decode(google_service_account_key.github-deploy-key.private_key)
  filename = "${path.module}/github-deploy-key.json"
}

# "Service Agent" credentials for infra repo (so it can manage more resources like cluster roles)
resource "google_service_account" "github-manage-gsa" {
  project      = var.project_id
  account_id   = "${substr(var.demo_name, 0, 12)}-github-manage-gsa"
  display_name = "${substr(var.demo_name, 0, 12)}-github-manage-gsa"
}
resource "google_project_iam_member" "github-manage-admin" {
  project = var.project_id
  role    = "roles/container.serviceAgent"
  member  = "serviceAccount:${google_service_account.github-manage-gsa.email}"
}
resource "google_service_account_key" "github-manage-key" {
  service_account_id = google_service_account.github-manage-gsa.name
}
resource "local_file" "github-manage-key" {
  content  = base64decode(google_service_account_key.github-manage-key.private_key)
  filename = "${path.module}/github-manage-key.json"
}

### GH Action Secrets ###

# subgraphs
resource "github_actions_secret" "subgraph_apollo_graph_secret" {
  for_each = {
    for index, subgraph in var.subgraphs : subgraph.name => subgraph
  }
  repository      = github_repository.subgraph_repos[each.key].name
  secret_name     = "APOLLO_GRAPH_ID"
  plaintext_value = var.apollo_graph_id
}
resource "github_actions_secret" "subgraph_apollo_secret" {
  for_each = {
    for index, subgraph in var.subgraphs : subgraph.name => subgraph
  }
  repository      = github_repository.subgraph_repos[each.key].name
  secret_name     = "APOLLO_KEY"
  plaintext_value = var.apollo_key
}
resource "github_actions_secret" "subgraph_cluster_prefix" {
  for_each = {
    for index, subgraph in var.subgraphs : subgraph.name => subgraph
  }
  repository      = github_repository.subgraph_repos[each.key].name
  secret_name     = "CLUSTER_PREFIX"
  plaintext_value = var.demo_name
}
resource "github_actions_secret" "subgraph_gcp_secret" {
  for_each = {
    for index, subgraph in var.subgraphs : subgraph.name => subgraph
  }
  repository      = github_repository.subgraph_repos[each.key].name
  secret_name     = "GCP_CREDENTIALS"
  plaintext_value = base64decode(google_service_account_key.github-deploy-key.private_key)
}

# infra repo secrets: the only different value is GCP_CREDENTIALS
resource "github_actions_secret" "infra_apollo_graph_secret" {
  repository      = github_repository.infra_repo.name
  secret_name     = "APOLLO_GRAPH_ID"
  plaintext_value = var.apollo_graph_id
}
resource "github_actions_secret" "infra_apollo_secret" {
  repository      = github_repository.infra_repo.name
  secret_name     = "APOLLO_KEY"
  plaintext_value = var.apollo_key
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
