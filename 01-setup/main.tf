provider "google" {
  project = var.project_id
  region  = var.project_region
}

// google_client_config allows us to generate a new token for each of the k8s providers as needed
// since they expire after 1 hour, this will need to be run semi-often and will need terraform apply or the `gcloud containers get-credentials` commands run
// lastly- this also allows us to instantiate the provider as a dependency of the GKE cluster, as it's only used for the secrets management
data "google_client_config" "main" {
  depends_on = [module.gke]
}
data "google_container_cluster" "dev" {
  depends_on = [module.gke]
  name       = "${var.demo_name}-dev"
  location   = var.project_region
}
data "google_container_cluster" "prod" {
  depends_on = [module.gke]
  name       = "${var.demo_name}-prod"
  location   = var.project_region
}

// we need two k8s providers to be able to handle the namespace + service account creation to avoid a dance between KRM and TF files for the end-user
provider "kubernetes" {
  alias = "k8s-dev"
  host  = "https://${data.google_container_cluster.dev.endpoint}"
  token = data.google_client_config.main.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.dev.master_auth[0].cluster_ca_certificate,
  )
}
provider "kubernetes" {
  alias = "k8s-prod"
  host  = "https://${data.google_container_cluster.prod.endpoint}"
  token = data.google_client_config.main.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.prod.master_auth[0].cluster_ca_certificate,
  )
}
