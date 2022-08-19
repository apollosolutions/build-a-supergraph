# 02 - Managed federation

⏱ estimated time: 3 minutes

## What you'll build

![Architecture diagram of the supergraph](diagram.png)

## Part A: Publishing subgraphs

Trigger the deploy workflows, this time setting `publish=true` to publish to Studio.

```sh
export APOLLO_KEY=<api key from 01-setup/terraform.tfvars>
export APOLLO_GRAPH_ID=<graphid> # graphref without @current

gh secret set APOLLO_KEY -b"${APOLLO_KEY}" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a

gh secret set APOLLO_KEY -b"${APOLLO_KEY}" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b

gh secret set APOLLO_GRAPH_ID -b"${APOLLO_GRAPH_ID}" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a

gh secret set APOLLO_GRAPH_ID -b"${APOLLO_GRAPH_ID}" --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b
```

Trigger the deploy workflows, this time setting `publish=true` to publish to Studio.

```sh
gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a \
  -f version=main \
  -f cluster=apollo-supergraph-k8s-dev \
  -f publish=true \
  -f variant=dev \
  -f dry-run=false \
  -f debug=false

gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-a \
  -f version=main \
  -f cluster=apollo-supergraph-k8s-prod \
  -f publish=true \
  -f variant=prod \
  -f dry-run=false \
  -f debug=false

gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b \
  -f version=main \
  -f cluster=apollo-supergraph-k8s-dev \
  -f publish=true \
  -f variant=dev \
  -f dry-run=false \
  -f debug=false

gh workflow run deploy-gke --repo $GITHUB_ORG/apollo-supergraph-k8s-subgraph-b \
  -f version=main \
  -f cluster=apollo-supergraph-k8s-prod \
  -f publish=true \
  -f variant=prod \
  -f dry-run=false \
  -f debug=false
```

## Part B: Deploy Apollo Router

```sh
kubectl port-forward svc/router 4000:80
open http://localhost:4000
```
