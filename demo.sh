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

function startForgeRock() {
  pushd $EKS_DEMO_FORGEROCK/bin || exit
  ./fr-start.sh
  popd || exit
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

function stopForgeRock() {
  pushd $EKS_DEMO_FORGEROCK/bin || exit
  ./fr-stop.sh
  popd || exit
}

function brew_update() {
    brew update && brew upgrade
}

case "$1" in
    start)
      case "$2" in
        all)
          brew_update && clear && startCluster && sleep 15 && startForgeRock
        ;;
        eks)
          startCluster
        ;;
        '')
          startCluster
        ;;
        fr)
          startForgeRock
        ;;
      esac
    ;;
    stop)
      case "$2" in
        "fr")
          stopForgeRock
        ;;
        "eks")
          stopCluster
        ;;
        '')
          stopForgeRock
          stopCluster
        ;;
        all)
          stopForgeRock
          stopCluster
        ;;
      esac
    ;;
    restart)
      case "$2" in
        "all")
          stopForgeRock && stopCluster && clear && brew_update && startCluster && sleep 15 && startForgeRock
        ;;
        "")
          stopCluster && clear && brew_update && startCluster
        ;;
        "eks")
          stopCluster && clear && brew_update && startCluster
        ;;
        "fr")
          stopForgeRock && sleep 5 && startForgeRock
        ;;
        *)
          echo Huh?
        ;;
      esac
    ;;
    *)
      echo $"Commands:"
      echo $" demo start        Start EKS cluster"
      echo $" demo start eks    Start EKS cluster"
      echo $" demo start fr     Start ForgeRock on cluster"
      echo $" demo start all    Start cluster and ForgeRock (incl brew update)"
      echo $" "
      echo $" demo stop         Stop EKS cluster"
      echo $" demo stop eks     Stop EKS cluster"
      echo $" demo stop fr      Stop Forgerock"
      echo $" demo stop all     Stop Forgerock and cluster"
      echo $" "
      echo $" demo restart      Restart EKS cluster"
      echo $" demo restart eks  Restart EKS cluster"
      echo $" demo restart fr   Restart ForgeRock"
      echo $" demo restart all  Restart EKS cluster and ForgeRock"
esac
