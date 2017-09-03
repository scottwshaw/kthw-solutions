#!/bin/bash
set -e

kubectl get csr | \
    while read -a l; do
	csr="${l[0]}"
	[ $csr != 'NAME' ] && ( kubectl certificate approve $csr )
    done





