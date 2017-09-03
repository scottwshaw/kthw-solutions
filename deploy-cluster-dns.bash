#!/bin/bash
set -e

kubectl create clusterrolebinding serviceaccounts-cluster-admin \
  --clusterrole=cluster-admin \
  --group=system:serviceaccounts

kubectl create -f /Users/sshaw/Documents/Development/Kubernetes/Tutorial/kubernetes-the-hard-way/services/kubedns.yaml

kubectl --namespace=kube-system get svc

kubectl create -f /Users/sshaw/Documents/Development/Kubernetes/Tutorial/kubernetes-the-hard-way/deployments/kubedns.yaml

kubectl --namespace=kube-system get pods
