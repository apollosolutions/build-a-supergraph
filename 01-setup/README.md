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
gcloud components update
gcloud auth application-default login
# expected output:
# > Credentials saved to file: [/Users/you/.config/gcloud/application_default_credentials.json]

export PROJECT=$(gcloud config get-value project)
gcloud projects list --filter="$PROJECT" --format="value(PROJECT_NUMBER)"
```

### Setup terraform variables

In `terraform.tfvars`:

```terraform
github_token = ""
github_username = ""
github_email = ""
project_id = ""
project_number = ""
```

## Part B: Provision resources

### Create repositories

- TODO

### Create Kubernetes clusters

```sh
terraform init
terraform plan
terraform apply
# takes 8 minutes
```

## Part C: Deploy applications

### Deploy subgraphs

- TODO: trigger deploy workflows (dev and prod)
- TODO: try them out over nodeports
