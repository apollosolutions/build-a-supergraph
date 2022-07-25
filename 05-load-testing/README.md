# 05 - Load testing and cleanup

⏱ estimated time: TODO

## Part C: Cleanup

```sh
terraform destroy
# takes 10 minutes

kubectl config delete-context supergraph-dev
kubectl config delete-context supergraph-prod
kubectl config delete-user gke_${PROJECT_ID}_us-east1_apollo-supergraph-k8s-dev
kubectl config delete-user gke_${PROJECT_ID}_us-east1_apollo-supergraph-k8s-prod
kubectl config delete-cluster gke_${PROJECT_ID}_us-east1_apollo-supergraph-k8s-dev
kubectl config delete-cluster gke_${PROJECT_ID}_us-east1_apollo-supergraph-k8s-prod
```
