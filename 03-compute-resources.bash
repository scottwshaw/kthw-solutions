#!/bin/bash
set -e

#
# VPC Network
#
gcloud compute networks create kubernetes-the-hard-way --mode custom

gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24

#
# Firewall Rules
#
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-checks \
  --allow tcp:8080 \
  --network kubernetes-the-hard-way \
  --source-ranges 209.85.204.0/22,209.85.152.0/22,35.191.0.0/16

gcloud compute firewall-rules list --filter "network kubernetes-the-hard-way"
