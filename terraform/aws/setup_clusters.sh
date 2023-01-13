#/bin/bash
set -euxo pipefail

# default vars
CLUSTER_PREFIX=${CLUSTER_PREFIX:-"apollo-supergraph-k8s"}
PROJECT_REGION=${PROJECT_REGION:-"us-east-1"}
PROJECT_CLUSTERS=("${CLUSTER_PREFIX}-dev" "${CLUSTER_PREFIX}-prod")
# end default vars

if [[ $(which aws) == "" ]]; then
  echo "aws not installed; please visit https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi

if [[ $(which eksctl) == "" ]]; then 
  echo "eksctl not installed; please visit https://eksctl.io/introduction/?h=install#installation"
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

# get AWS account ID (numeric)
ACCOUNT_ID=`aws sts get-caller-identity --output text --query Account`

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json || echo ""
curl -Lo v2_4_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_ingclass.yaml

environment_setup(){
    echo "Configuring Kubeconfig for ${1}..."
    # https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-configure-kubectl
    eksctl utils write-kubeconfig --cluster=${1} --region=${PROJECT_REGION}
    kubectx ${1}=.
    # https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
    # install LB Controller 
    kubectl apply \
      --validate=false \
      -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
    sleep 15

    # there may need more done in order to work- see step 5 in the above link
    # create necessary service account
    eksctl create iamserviceaccount \
      --cluster=${1} \
      --namespace=kube-system \
      --name="aws-load-balancer-controller" \
      --role-name "AmazonEKSLoadBalancerControllerRole-${1}" \
      --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
      --approve \
      --override-existing-serviceaccounts
    curl -Lo v2_4_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml
    sed -i.bak -e '480,488d' ./v2_4_4_full.yaml
    sed -i.bak -e "s|your-cluster-name|${1}|" ./v2_4_4_full.yaml
    kubectl apply -f v2_4_4_full.yaml
    kubectl apply -f v2_4_4_ingclass.yaml
    # validate with: kubectl get deployment -n kube-system aws-load-balancer-controller
}

for c in "${PROJECT_CLUSTERS[@]}"; do
    environment_setup $c
done
