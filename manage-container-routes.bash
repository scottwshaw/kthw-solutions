#!/bin/bash
set -e

#
# This is an executable script to be run on the development machine
#

kubectl get nodes \
	--output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}' | \
    while read -a l; do
	nexthop="${l[0]}"
	destrange="${l[1]}"
	routename="kubernetes-route-`(echo $destrange) | tr '.' '-' | tr '/' '-'`"
	gcloud compute routes create $routename \
	       --network kubernetes-the-hard-way \
	       --next-hop-address $nexthop \
	       --destination-range $destrange
    done

