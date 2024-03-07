#!/usr/bin/env bash

cd `dirname $0`

function run() {
    eval "$0 $INSTANCE $1"
}

function startCluster() {
  AWS_ACCOUNT_ID=$(aws --output json sts get-caller-identity  | jq -r '.Account')

  eksctl create cluster -f eks-demo.yaml

  #Alle volgende cmd's gaan parallel
  kubectl create secret generic aws --namespace flux-system \
    --from-literal=AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID \
    --from-literal=AWS_REGION=us-west-2 \
    --from-literal=CLUSTER_NAME=eks-demo &

  kubectl apply -f .secrets/github.yaml &

  gpg --export-secret-keys --armor 6A3D2EDFCB37F13284F42BAA2BFA724C957A2A9D | \
    kubectl create secret generic sops-gpg --namespace=flux-system --from-file=sops.asc=/dev/stdin &

  #En wachten tot alle jobs klaar zijn
  wait < <(jobs -p)
}

function stopCluster() {
  # Context is relevant if more than one cluster is running, like a minikube cluster
  flux suspend kustomization --context console@eks-demo.us-west-2.eksctl.io flux-system
  flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app
  flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent prometheus
  sleep 1
  flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app-db
  sleep 1
  flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app-crossplane
  # Wait, to let DNS controller remove all CNAME and A records
  sleep 60

  eksctl delete cluster eks-demo --wait
}

case "$1" in
    start)
      startCluster
    ;;
    stop)
      stopCluster
    ;;
    restart)
      startCluster && stopCluster
    ;;
    *)
      echo $"Commands:"
      echo $" demo start        Start EKS cluster"
      echo $" demo stop         Stop EKS cluster"
      echo $" demo restart      Restart EKS cluster"
esac
