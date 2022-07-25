# 01 - Setup

⏱ estimated time: TODO

## What you'll build

TODO: diagram with just repos, clusters, and subgraphs

## Part A: Gather accounts and credentials

### Clone this repo

```
git clone https://github.com/apollosolutions/build-a-supergraph.git
cd build-a-supergraph
```

### Install dependencies

- [GCloud CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

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

```sh
export PROJECT_ID="<your-project-id>"

gcloud components update
gcloud components install gke-gcloud-auth-plugin
gcloud auth application-default login
# expected output:
# > Credentials saved to file: [/Users/you/.config/gcloud/application_default_credentials.json]

gcloud config set project ${PROJECT_ID}
gcloud services enable \
  container.googleapis.com \
  secretmanager.googleapis.com \
  cloudasset.googleapis.com \
  storage.googleapis.com
```

### Setup terraform variables

In `terraform.tfvars`:

```terraform
github_token = ""
github_username = ""
github_email = ""
project_id = ""
project_region = "us-east1"
```

## Part B: Provision resources

### Create repositories

- TODO

### Create Kubernetes clusters

```sh
cd 01-setup
terraform init # 2 minutes
terraform plan
terraform apply # will prompt for confirmation
# takes 8 minutes
```

### Setup kubectl

```sh
gcloud container clusters get-credentials apollo-supergraph-k8s-dev --zone us-east1 --project $PROJECT_ID

kubectl config rename-context gke_$PROJECT_ID_us-east1_apollo-supergraph-k8s-dev supergraph-dev

gcloud container clusters get-credentials apollo-supergraph-k8s-prod --zone us-east1 --project $PROJECT_ID

kubectl config rename-context gke_$PROJECT_ID_us-east1_apollo-supergraph-k8s-prod supergraph-prod
```

Now you can inspect your clusters with

```sh
kubectl config set-context supergraph-dev
kubectl get all --all-namespaces
```

## Part C: Deploy applications

### Deploy subgraphs

- TODO: trigger deploy workflows (dev and prod)
- TODO: try them out over nodeports
