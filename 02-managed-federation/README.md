# 02 - Managed federation

⏱ Estimated time: 5 minutes

## What you'll build

![Architecture diagram of the supergraph](02-diagram-fj.png)

## Part A: Publish subgraph schemas to Apollo GraphOS

In both **subgraph-a** and **subgraph-b** repositories:

- Edit `.github/workflows/Merge to Main.yml`
- Add a new job to the bottom of the file:
  ```yaml
  publish:
    needs: [deploy_aws, deploy_gcp]
    if: always() &&
      (needs.deploy_aws.result == 'success' || needs.deploy_aws.result == 'skipped') &&
      (needs.deploy_gcp.result == 'success' || needs.deploy_gcp.result == 'skipped')
    uses: ./.github/workflows/_rover-subgraph-publish.yml
    secrets: inherit
    with:
      subgraph_name: subgraph-a # change to subgraph-b in that repo
      variant: dev
  ```
- After merging the code to the `main` branch, the `Merge to Main` action will build the docker container, deploy the subgraph application, and finally publish the subgraph schema to Apollo GraphOS.
- Visit your graph in GraphOS Studio to see that the subgraph schemas published successfully and it built a new supergraph schema for the `dev` variant.
- Add a new job to `.github/workflows/Manual Deploy.yml`:
  ```yaml
  publish:
    needs: [deploy_aws, deploy_gcp]
    if: always() &&
      (needs.deploy_aws.result == 'success' || needs.deploy_aws.result == 'skipped') &&
      (needs.deploy_gcp.result == 'success' || needs.deploy_gcp.result == 'skipped')
    uses: ./.github/workflows/_rover-subgraph-publish.yml
    secrets: inherit
    with:
      subgraph_name: subgraph-a # change to subgraph-b in that repo
      variant: ${{ inputs.environment }}
  ```
- After merging this change to main, trigger the `Manual Deploy` action to deploy and publish to production:

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

- Visit your graph in GraphOS Studio to see that the subgraph schemas published successfully and it built a new supergraph schema for the `prod` variant.

## Part B: Deploy Apollo Router

Now that the supergraph schema is available via Apollo Uplink, you can deploy the router:

```
gh workflow run "Deploy Router" --repo $GITHUB_ORG/apollo-supergraph-k8s-infra \
  -f environment=dev \
  -f dry-run=false \
  -f debug=false

gh workflow run "Deploy Router" --repo $GITHUB_ORG/apollo-supergraph-k8s-infra \
  -f environment=prod \
  -f dry-run=false \
  -f debug=false
```

Make a GraphQL request to the router via its IP address:

```sh
ROUTER_IP=$(kubectl get ingress -n router -o jsonpath="{.*.*.status.loadBalancer.ingress.*.ip}")
open http://$ROUTER_IP
```

The Google Cloud ingress may take a few minutes to start. If you don't want to wait for an IP address you can use `port-forward`:

```sh
kubectl port-forward service/router -n router 4000:80
```

## Onward!

[Step 3: Schema Checks](../03-schema-checks/)
