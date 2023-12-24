#!/bin/bash

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
