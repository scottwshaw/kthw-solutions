#!/bin/bash
set -e

. ./gcloudexec.bash

# download and install K8 controllers
for host in controller-0 controller-1 controller-2; do
    gcloudexec ${host} 'wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kubectl"'
    gcloudexecall ${host} \
		  'chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl' \
		  'sudo mv -u kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/'
done

# Config the API Server
for host in controller-0 controller-1 controller-2; do
    gcloudexecall ${host} \
		  'if [ ! -d "/var/lib/kubernetes" ]; then sudo mkdir -p /var/lib/kubernetes; fi' \
		  'sudo mv -u ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem encryption-config.yaml /var/lib/kubernetes/'
done

# Copy the config and startup scripts to the controllers and execute
for host in controller-0 controller-1 controller-2; do
  gcloud compute scp remote-exec/config-control-plane.bash remote-exec/start-control-plane.bash ${host}:~/
  gcloudexecall ${host} \
		'chmod a+x config-control-plane.bash start-control-plane.bash' \
		'~/config-control-plane.bash' \
		'~/start-control-plane.bash'
done

# Wait for everything to come up
sleep 10 
echo These should be healthy
for host in controller-0 controller-1 controller-2; do
    gcloudexec ${host} 'kubectl get componentstatuses'
done






