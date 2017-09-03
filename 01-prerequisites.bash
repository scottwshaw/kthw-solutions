#!/bin/bash
set -e

echo `gcloud version` should be greater than or equal to 169.0.0
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-f

