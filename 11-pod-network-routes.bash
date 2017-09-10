#!/bin/bash
set -e

. ./gcloudexec.bash


for i in 0 1 2; do
    l=$(gcloud compute instances describe "worker-"$i \
    	       --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)')
    nexthop="${l[0]}"
    destrange="${l[1]}"
    routename="kubernetes-route-`(echo $destrange) | tr '.' '-' | tr '/' '-'`"
    gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
	   --network kubernetes-the-hard-way \
	   --next-hop-address 10.240.0.2${i} \
	   --destination-range 10.200.${i}.0/24
done

gcloud compute routes list --filter "network kubernetes-the-hard-way"
