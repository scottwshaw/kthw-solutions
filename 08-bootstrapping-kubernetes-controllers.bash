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

# Create external load balancer network entities

gcloud compute http-health-checks create kube-apiserver-health-check \
       --description "Kubernetes API Server Health Check" \
       --port 8080 \
       --request-path /healthz

gcloud compute target-pools create kubernetes-target-pool \
       --http-health-check=kube-apiserver-health-check

gcloud compute target-pools add-instances kubernetes-target-pool \
       --instances controller-0,controller-1,controller-2

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
				   --region $(gcloud config get-value compute/region) \
				   --format 'value(name)')

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
       --address ${KUBERNETES_PUBLIC_ADDRESS} \
       --ports 6443 \
       --region $(gcloud config get-value compute/region) \
       --target-pool kubernetes-target-pool

# Verify load balancer

KUBERNETES_PUBLIC_IP_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
				      --region $(gcloud config get-value compute/region) \
				      --format 'value(address)')

CORRECT_OUTPUT="{ \"major\": \"1\", \
		  \"minor\": \"7\", \
		  \"gitVersion\": \"v1.7.4\", \
		  \"gitCommit\": \"793658f2d7ca7f064d2bdf606519f9fe1229c381\", \
		  \"gitTreeState\": \"clean\", \
		  \"buildDate\": \"2017-08-17T08:30:51Z\", \
		  \"goVersion\": \"go1.8.3\", \
		  \"compiler\": \"gc\",\
		  \"platform\": \"linux/amd64\" }"

echo you should see the following output:
echo $CORRECT_OUTPUT

curl --cacert ca.pem https://${KUBERNETES_PUBLIC_IP_ADDRESS}:6443/version







