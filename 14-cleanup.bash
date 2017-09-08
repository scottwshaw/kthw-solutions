#!/bin/bash

gcloud -q compute instances delete \
       controller-0 controller-1 controller-2 \
       worker-0 worker-1 worker-2

gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
       --region $(gcloud config get-value compute/region)
gcloud -q compute target-pools delete kubernetes-target-pool
gcloud -q compute http-health-checks delete kube-apiserver-health-check

gcloud -q compute addresses delete kubernetes-the-hard-way

gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-checks

gcloud -q compute networks subnets delete kubernetes

gcloud -q compute networks delete kubernetes-the-hard-way
