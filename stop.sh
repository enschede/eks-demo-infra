#!/bin/bash

flux suspend kustomization --context console@eks-demo.us-west-2.eksctl.io flux-system
flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app
sleep 1
flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app-db
sleep 1
flux delete kustomization --context console@eks-demo.us-west-2.eksctl.io --silent eks-demo-app-crossplane
sleep 60

eksctl delete cluster eks-demo --wait
