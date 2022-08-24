#/bin/bash
set -euxo pipefail

# default vars
CLUSTER_PREFIX=${CLUSTER_PREFIX:-"apollo-supergraph-k8s"}
PROJECT_REGION=${PROJECT_REGION:-"us-east1"}
PROJECT_CLUSTERS=("${CLUSTER_PREFIX}-dev" "${CLUSTER_PREFIX}-prod")
# end default vars

if [[ $(which gcloud) == "" ]]; then
  echo "gcloud not installed"
  exit 1
fi

if [[ $(which kubectl) == "" ]]; then
  echo "kubectl not installed"
  exit 1
fi

if [[ $(which kubectx) == "" ]]; then
  echo "kubectx not installed"
  exit 1
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "Must provide PROJECT_ID in environment" 1>&2
  exit 1
fi

environment_setup(){
    echo "Configuring Kubeconfig for ${1}..."
    gcloud container clusters get-credentials ${1} --zone ${PROJECT_REGION} --project ${PROJECT_ID}

    # short context aliases
    kubectx ${1}=.

    kubectl create namespace "router"
    kubectl create serviceaccount -n "router" "secrets-csi-k8s"
    kubectl annotate serviceaccount -n "router" "secrets-csi-k8s" iam.gke.io/gcp-service-account=secrets-csi-k8s@$PROJECT_ID.iam.gserviceaccount.com
    gcloud iam service-accounts add-iam-policy-binding \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${PROJECT_ID}.svc.id.goog[router/secrets-csi-k8s]" \
        secrets-csi-k8s@$PROJECT_ID.iam.gserviceaccount.com

    # apollo key for Router
    gcloud secrets add-iam-policy-binding apollo-key \
        --member="serviceAccount:secrets-csi-k8s@$PROJECT_ID.iam.gserviceaccount.com" \
        --role='roles/secretmanager.secretAccessor'

    csi_setup $1
}

csi_setup(){
    echo "Installing CSI Driver on ${1}..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/rbac-secretproviderclass.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/csidriver.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/secrets-store.csi.x-k8s.io_secretproviderclasses.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/secrets-store.csi.x-k8s.io_secretproviderclasspodstatuses.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/secrets-store-csi-driver.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/rbac-secretprovidersyncing.yaml
    kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/deploy/provider-gcp-plugin.yaml
}

for c in "${PROJECT_CLUSTERS[@]}"; do
    environment_setup $c
done
