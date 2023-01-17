# 01 - Setup

⏱ Estimated time: 45 minutes

## What you'll build

![Architecture diagram of the supergraph](01-diagram-fj.png)

## Part A: Gather accounts and credentials

### Clone this repo

```
git clone https://github.com/apollosolutions/build-a-supergraph.git
cd build-a-supergraph
git pull
```

### Install dependencies

#### GCP

- [GCloud CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kubectx](https://github.com/ahmetb/kubectx#installation)
- [Github CLI](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/download/)
- Optional: [Helm](https://helm.sh/docs/intro/install/)

#### AWS

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [eksctl](https://eksctl.io/introduction/#installation)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kubectx](https://github.com/ahmetb/kubectx#installation)
- [Github CLI](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/download/)
- Optional: [Helm](https://helm.sh/docs/intro/install/)

### Gather accounts

- [Github](https://github.com/signup)
- [Apollo GraphOS](https://studio.apollographql.com/signup?referrer=build-a-supergraph)
- [Google Cloud](https://console.cloud.google.com/freetrial)
  - Must have a project [with billing enabled](https://cloud.google.com/resource-manager/docs/creating-managing-projects#gcloud)

### Gather credentials

#### <image src="../images/gcp.svg" height="13" style="margin:auto;" /> GCP

- Google Cloud project ID
- [Github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  - [Settings > Developer Settings > Personal Access Tokens](https://github.com/settings/tokens)
  - Grant it permissions to the following scopes:
    - `repo` (for creating repos)
    - `delete_repo` (for cleanup at the end)
- [Apollo GraphOS Personal API key](https://studio.apollographql.com/user-settings/api-keys)

#### <image src="../images/aws.svg" height="13" style="margin:auto;" /> AWS

- [AWS Access Key and Secret for use with the AWS CLI*](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [Github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  - [Settings > Developer Settings > Personal Access Tokens](https://github.com/settings/tokens)
  - Grant it permissions to the following scopes:
    - `repo` (for creating repos)
    - `delete_repo` (for cleanup at the end)
- [Apollo GraphOS Personal API key](https://studio.apollographql.com/user-settings/api-keys)

\* Please note to use an account with Administrator priviledges, or at minimum, the ability to run: 

* Terraform, which creates: 
  * IAM user and policy
  * EKS cluster and node groups, and associates IAM permissions to Kubernetes service accounts
  * VPC and subnets

### Export all necessary variables

First, change directories in the cloud provider you wish to use. All terraform is within the `terraform` root level folder, with each cloud provider having a subfolder within. For the below examples, we'll assume GCP, however the others will use the same commands. 

Make a copy of `.env.sample` called `.env` to keep track of these values. You can always run `source .env` to reload all environment variables in a new terminal session.

```sh
cd terraform/gcp
cp .env.sample .env
```

Edit the new `.env` file:

```sh
export PROJECT_ID="<your google cloud project id>" # if using AWS, you will not see this line and can omit this
export APOLLO_KEY="<your apollo personal api key>"
export GITHUB_ORG="<your github account name or organization name>"
export TF_VAR_github_token="<your github personal access token>"
```

Run this script to create your graph and get environment variables for GraphOS:

```sh
cd terraform/gcp
source .env
./create_graph.sh
```

The script adds a couple more environment variables to `.env`, so reload your environment now:

```sh
source .env
```

### Run setup commands

#### <image src="../images/gcp.svg" height="13" style="margin:auto;" /> GCP

```sh
gcloud components update
gcloud components install gke-gcloud-auth-plugin
gcloud auth login

gcloud config set project ${PROJECT_ID}
gcloud services enable \
  container.googleapis.com \
  secretmanager.googleapis.com \
  cloudasset.googleapis.com \
  storage.googleapis.com
gh auth login
```

#### <image src="../images/aws.svg" height="13" style="margin:auto;" /> AWS

```sh
aws configure
gh auth login
```

#### General

<details>
  <summary>Optional: how do I specify a different name for clusters and repos? (The default is "apollo-supergraph-k8s".)</summary>

Before running `create_graph.sh`, `setup_clusters.sh`, or `terraform apply` export the prefix as as environment variables:

```sh
export CLUSTER_PREFIX=my-custom-prefix
export TF_VAR_demo_name=$CLUSTER_PREFIX
```

</details>

## Part B: Provision resources

<details>
  <summary>Have you run this tutorial before?</summary>

You may need to clean up your Github packages before creating new repos of the same name. Visit `https://github.com/<your github username>?tab=packages` and delete the packages created by the previous versions of the repos.

</details>

### Create Kubernetes clusters, basic infrastructure, and Github repositories

**Note: The following commands will create resources on your cloud provider account, and begin to accrue a cost.** The example infrastructure defaults to a lower-cost environment (small node count and instance size), however it will not be covered by either of GCP's or AWS's free tiers.

```sh
cd terraform/gcp
terraform init # takes about 2 minutes
terraform apply # will print plan then prompt for confirmation
# takes about 10-15 minutes
```

Expected output:

```
kubernetes_cluster_names = {
  "dev" = "apollo-supergraph-k8s-dev"
  "prod" = "apollo-supergraph-k8s-prod"
}
repo_infra = "https://github.com/you/apollo-supergraph-k8s-infra"
repo_subgraph_a = "https://github.com/you/apollo-supergraph-k8s-subgraph-a"
repo_subgraph_b = "https://github.com/you/apollo-supergraph-k8s-subgraph-b"
```

<details>
  <summary>What does this do?</summary>

Terraform provisions:

- Two Kubernetes clusters (dev and prod)
- Three Github repos (subgraph-a, subgraph-b, infra)
- Github action secrets for GCP/AWS and Apollo credentials

The subgraph repos are configured to build and deploy to the `dev` cluster once they're provisioned. (The deploy will fail the first time. See "Note about "initial commit" errors" below.)

</details>

### Run cluster setup script

After creating the necessary clusters, you will need to run the included cluster setup script:

```sh
cd terraform/gcp
./setup_clusters.sh # about 2 minutes
```

<details>
  <summary>What does this do?</summary>

For both `dev` and `prod` clusters:

- Configures your local `kubectl` so you can inspect your clusters
- For GCP users:
  - Configures namespace, service account, and role bindings for Open Telemetry and Google Traces.
- For AWS users:
  - Configures load balancer controller policy and IAM service account

</details>

After this completes, you're ready to deploy your subgraphs!

## Part C: Deploy applications

### Deploy subgraphs to dev

```sh
gh workflow run "Merge to Main" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a
gh workflow run "Merge to Main" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b
# this deploys a dependency for prod, see note below
gh workflow run "Deploy Open Telemetry Collector" --repo $GITHUB_ORG/apollo-supergraph-k8s-infra
```

<details>
  <summary>Note about "initial commit" errors</summary>

When terraform creates the repositories, they immediately kick off initial workflow runs. But the secrets needed are available at that point. The "initial commit" runs will fail, but we're just re-running them with the commands above.

</details>

You can try out a subgraph using port forwarding:

```sh
kubectx apollo-supergraph-k8s-dev
kubectl port-forward service/graphql -n subgraph-a 4000:4000
```

Then visit [http://localhost:4000/](http://localhost:4000/).

### Deploy subgraphs to prod

Commits to the `main` branch of the subgraph repos are automatically built and deployed to the `dev` cluster. To deploy to prod, run the deploy actions:

```sh
gh workflow run "Manual Deploy" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a \
  -f version=main \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false

gh workflow run "Manual Deploy" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b \
  -f version=main \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false
```

```sh
kubectx apollo-supergraph-k8s-prod
kubectl port-forward service/graphql -n subgraph-a 4000:4000
```

Then visit [http://localhost:4000/](http://localhost:4000/).

## Onward!

[Step 2: Managed Federation](../02-managed-federation/)
