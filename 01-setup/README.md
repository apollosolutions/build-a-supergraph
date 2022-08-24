# 01 - Setup

⏱ estimated time: 45 minutes (TODO verify)

## What you'll build

![Architecture diagram of the supergraph](diagram.png)

## Part A: Gather accounts and credentials

### Clone this repo

```
git clone https://github.com/apollosolutions/build-a-supergraph.git
cd build-a-supergraph
```

### Install dependencies

- [GCloud CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kubectx](https://github.com/ahmetb/kubectx#installation)
- [Github CLI](https://cli.github.com/)
- Optional: [Helm](https://helm.sh/docs/intro/install/)

### Gather accounts

- [Github](https://github.com/signup)
- [Apollo Studio](https://studio.apollographql.com/signup?referrer=build-a-supergraph)
- [Google Cloud](https://console.cloud.google.com/freetrial)
  - Must have a project [with billing enabled](https://cloud.google.com/resource-manager/docs/creating-managing-projects#gcloud)

### Gather credentials

- [Github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  - [Settings > Developer Settings > Personal Access Tokens](https://github.com/settings/tokens)
  - Grant it permissions to the following scopes:
    - `repo` (for creating repos)
    - `delete-repo` (for cleanup at the end)
- [Apollo Studio Personal API key](https://studio.apollographql.com/user-settings/api-keys)

```sh
export PROJECT_ID="<your-project-id>"
export APOLLO_KEY="<your personal apollo api key>"

# gcloud
gcloud components update
gcloud components install gke-gcloud-auth-plugin
gcloud auth application-default login

gcloud config set project ${PROJECT_ID}
gcloud services enable \
  container.googleapis.com \
  secretmanager.googleapis.com \
  cloudasset.googleapis.com \
  storage.googleapis.com

# github
gh auth login

# apollo
./create_graph.sh
# Save the output for the next step! Example:
#
# New terraform variables:
#
# apollo_key      = "service:apollo-supergraph-k8s-5ac437:asdasdfasdfasd"
# apollo_graph_id = "apollo-supergraph-k8s-asdfas"
```

<details>
  <summary>Optional: how do I specify a different name for clusters and repos? (The default is "apollo-supergraph-k8s".)</summary>

1.  Before running `create_graph.sh` or `setup_clusters.sh`, export the prefix as a variable:

    ```sh
    export CLUSTER_PREFIX=my-custom-prefix
    ```

2.  Before running `terraform apply`, add another variable to `terraform.tfvars`:

    ```terraform
    demo_name = "my-custom-prefix"
    ```

</details>

### Setup terraform variables

Copy `terraform.sample_tfvars` to `terraform.tfvars` within the `01-setup` folder and replace the values according to the comments.

## Part B: Provision resources

### Create Kubernetes clusters, basic infrastructure, and Github repositories

**Note: The following commands will create resources on your GCP account, and begin to accrue a cost.** The example infrastructure defaults to a lower-cost environment (small node count and instance size), however it will not be covered by GCP's free tier.

Once you have populated your `terraform.tfvars` file, run the following commands:

```sh
cd 01-setup
terraform init # takes about 2 minutes
terraform apply # will print plan then prompt for confirmation
# takes about 10-15 minutes
```

Expected output:

```
kubernetes_cluster_names = {
  "dev" = "apollo-supergraph-k8s-dev"
  "prod" = "apollo-supergraph-k8s-prod"
  "infra" = "apollo-supergraph-k8s-infra"
}
repo_infra = "https://github.com/you/apollo-supergraph-k8s-infrastructure"
repo_subgraph_a = "https://github.com/you/apollo-supergraph-k8s-subgraph-a"
repo_subgraph_b = "https://github.com/you/apollo-supergraph-k8s-subgraph-b"
```

<details>
  <summary>What does this do?</summary>

Terraform provisions:

- Three Kubernetes clusters (dev, prod, infra-tooling)
- VPCs for the clusters to communicate with one another
- Runtime secrets for the Router to communicate with Studio
- Three Github repos (subgraph-a, subgraph-b, infra)
- Github action secrets for GCP and Apollo credentials

The subgraph repos are configured to build and deploy to the `dev` cluster once they're provisioned.

</details>

### Run cluster setup script

After creating the necessary clusters, you will need to run the included cluster setup script:

```sh
./setup_clusters.sh # about 3 minutes
```

<details>
  <summary>What does this do?</summary>

For both `dev` and `prod` clusters:

- Configures your local `kubeconfig` with access information, making it easier to apply local Helm charts
- Creates a `router` namespace we'll use to deploy the Apollo Router
- Creates a Kubernetes service account (`secrets-csi-k8s`) used for secrets access
- Installs the [GCP CSI Driver for Kubernetes](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp)
  - The CSI driver is used by the Apollo Router infrastructure later to access the Apollo API key and graph reference securely, using GCP's Secret Manager
- Configures permissions to allow access to the secrets within Secret Manager

</details>

After completing, you should be able to run `kubectl port-forward` to test the subgraphs in `dev`:

```sh
kubectx apollo-supergraph-k8s-dev
kubectl port-forward service/subgraph-a-chart 4000:4000
open http://localhost:4000
```

## Part C: Deploy applications

### Deploy subgraphs to prod

Commits to the `main` branch of the subgraph repos are automatically built and deployed to the `dev` cluster. To deploy to prod, run the deploy actions:

```sh
gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a \
  -f version=main \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false

gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b \
  -f version=main \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false
```

```sh
kubectx apollo-supergraph-k8s-prod
kubectl port-forward service/subgraph-a-chart 4000:4000
open http://localhost:4000
```
