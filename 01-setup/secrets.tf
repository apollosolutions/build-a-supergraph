// for the IAM bindings, we need the k8s namepspaces to exist- this creates them for us in TF. 
// Additionally, since the Router is the only service needing access, we'll only create on prod & dev
resource "kubernetes_namespace" "k8s-namespace-dev" {
  provider = kubernetes.k8s-dev
  metadata {
    name = "router"
  }
}
resource "kubernetes_namespace" "k8s-namespace-prod" {
  provider = kubernetes.k8s-prod
  metadata {
    name = "router"
  }
}

// set up the workload identity mappings to a k8s service account
module "workload-identity-dev" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  providers = {
    kubernetes = kubernetes.k8s-dev
  }
  automount_service_account_token = true
  depends_on = [
    module.gke,
    kubernetes_namespace.k8s-namespace-dev,
  ]
  name         = "secrets-csi-k8s-dev"
  namespace    = "router"
  project_id   = var.project_id
  roles        = []
  cluster_name = module.gke["dev"].name
}
module "workload-identity-prod" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  providers = {
    kubernetes = kubernetes.k8s-prod
  }
  automount_service_account_token = true
  depends_on = [
    module.gke,
    kubernetes_namespace.k8s-namespace-prod,
  ]
  name         = "secrets-csi-k8s-prod"
  namespace    = "router"
  project_id   = var.project_id
  roles        = []
  cluster_name = module.gke["prod"].name
}

// APOLLO_KEY
resource "google_secret_manager_secret" "apollo-key" {
  project   = var.project_id
  secret_id = "apollo-key"

  replication {
    user_managed {
      replicas {
        location = var.project_region
      }
    }
  }
}
resource "google_secret_manager_secret_version" "apollo-key-version" {
  secret = google_secret_manager_secret.apollo-key.id

  secret_data = var.apollo_key
}

// APOLLO_GRAPH_REF
resource "google_secret_manager_secret" "apollo-graph-ref" {
  project   = var.project_id
  secret_id = "apollo-graph-ref"

  replication {
    user_managed {
      replicas {
        location = var.project_region
      }
    }
  }
}
resource "google_secret_manager_secret_version" "apollo-graph-ref-version" {
  secret = google_secret_manager_secret.apollo-graph-ref.id

  secret_data = var.apollo_graph_ref
}

// set up the secrets IAM binding to the workload identities above
resource "google_secret_manager_secret_iam_binding" "apollo-key-dev-binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.apollo-key.id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    module.workload-identity-dev.gcp_service_account_fqn,
  ]
}
resource "google_secret_manager_secret_iam_binding" "apollo-graph-ref-dev-binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.apollo-graph-ref.id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    module.workload-identity-dev.gcp_service_account_fqn,
  ]
}

resource "google_secret_manager_secret_iam_binding" "apollo-key-prod-binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.apollo-key.id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    module.workload-identity-prod.gcp_service_account_fqn,
  ]
}
resource "google_secret_manager_secret_iam_binding" "apollo-graph-ref-prod-binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.apollo-graph-ref.id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    module.workload-identity-prod.gcp_service_account_fqn,
  ]
}
