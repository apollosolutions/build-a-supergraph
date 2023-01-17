## 06 - Cleanup

⏱ Estimated time: 15 minutes

Running Google Cloud resources will continue to incur costs on your account so we have documented all the steps to take for a proper tear-down.

### Automated cleanup

### Cloud-specific steps

There are a few cloud-specific steps you'll need to take.

#### <image src="../images/gcp.svg" height="13" style="margin:auto;" /> GCP

In order to delete some non-Kubernetes resources created by Google Cloud, it's easiest to just delete everything:

```sh
kubectx apollo-supergraph-k8s-dev
kubectl delete daemonsets,replicasets,services,deployments,pods,rc,ingress --all --all-namespaces
```

The command may hang at the end. You can kill the process (`ctrl-c`) and repeat with the prod cluster:

```
kubectx apollo-supergraph-k8s-prod
kubectl delete daemonsets,replicasets,services,deployments,pods,rc,ingress --all --all-namespaces
```

#### <image src="../images/aws.svg" height="13" style="margin:auto;" /> AWS

In order to ensure the load balancers are properly removed, and the iamservice roles are removed, please run:

```
gh workflow run "Uninstall Router" --repo $GITHUB_ORG/apollo-supergraph-k8s-infra
open https://github.com/$GITHUB_ORG/apollo-supergraph-k8s-infra/actions/workflows/uninstall-router.yaml
``` 

And wait for the action to complete on the opened screen. 

Once finished, run the following, replacing `apollo-supergraph-k8s` with the appropriate cluster prefix if modified: 

```sh
# dev
eksctl delete iamserviceaccount \
    --cluster=apollo-supergraph-k8s-dev \
    --name="aws-load-balancer-controller" 
aws cloudformation delete-stack --stack-name eksctl-apollo-supergraph-k8s-dev-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
# prod
eksctl delete iamserviceaccount \
    --cluster=apollo-supergraph-k8s-prod \
    --name="aws-load-balancer-controller" 
aws cloudformation delete-stack --stack-name eksctl-apollo-supergraph-k8s-prod-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
```

### Remaining steps

Then you can destroy all the provisioned resources (Kubernetes clusters, GitHub repositories) with terraform:

```sh
cd terraform/<cloud_provider>
terraform destroy # takes 10 minutes
```

Lastly, you can remove the contexts from your `kubectl`:

```sh
kubectl config delete-context apollo-supergraph-k8s-dev
kubectl config delete-context apollo-supergraph-k8s-prod
```

Terraform does not delete the Docker containers from GitHub. Visit `https://github.com/<your github username>?tab=packages` and delete the packages created by the previous versions of the repos.

## Congratulations! 🎉

You've completed the tutorial!
