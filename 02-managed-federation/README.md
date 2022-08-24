# 02 - Managed federation

⏱ estimated time: 3 minutes

## What you'll build

![Architecture diagram of the supergraph](diagram.png)

## Part A: Publish subgraph schemas to Apollo Studio

TODO: describe adding/enabling rover subgraph publish in deploy workflows

## Part B: Deploy Apollo Router

```
gh workflow run "Deploy Router GKE" --repo $GITHUB_ORG/apollo-supergraph-k8s-infrastructure \
  -f environment=dev \
  -f dry-run=false \
  -f debug=false

gh workflow run "Deploy Router GKE" --repo $GITHUB_ORG/apollo-supergraph-k8s-infrastructure \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false
```

```sh
kubectl port-forward svc/router -n router 4000:80
open http://localhost:4000
```
