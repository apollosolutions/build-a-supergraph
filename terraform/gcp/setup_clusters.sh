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

    # short context aliases: supports `kubectx apollo-supergraph-k8s-dev`
    kubectx ${1}=.

    # monitoring setup: namespace, service account, and binding
    # the service account name matches the otel collector's service account in its helm chart
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create serviceaccount -n "monitoring" "metrics-writer" --dry-run=client -o yaml | kubectl apply -f -
    kubectl annotate serviceaccount -n "monitoring" "metrics-writer" "iam.gke.io/gcp-service-account=${CLUSTER_PREFIX:0:12}-metrics-writer@$PROJECT_ID.iam.gserviceaccount.com" --overwrite
    gcloud iam service-accounts add-iam-policy-binding \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${PROJECT_ID}.svc.id.goog[monitoring/metrics-writer]" \
        "${CLUSTER_PREFIX:0:12}-metrics-writer@$PROJECT_ID.iam.gserviceaccount.com"
}

for c in "${PROJECT_CLUSTERS[@]}"; do
    environment_setup $c
done
