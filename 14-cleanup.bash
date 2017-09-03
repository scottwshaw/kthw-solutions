#!/bin/bash

gcloud -q compute instances delete \
       controller-0 controller-1 controller-2 \
       worker-0 worker-1 worker-2

gcloud -q compute addresses delete kubernetes-the-hard-way

gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-checks

gcloud -q compute networks subnets delete kubernetes

gcloud -q compute networks delete kubernetes-the-hard-way
