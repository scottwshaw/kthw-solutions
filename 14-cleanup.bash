#!/bin/bash

gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-checks

gcloud -q compute networks subnets delete kubernetes

gcloud -q compute networks delete kubernetes-the-hard-way
