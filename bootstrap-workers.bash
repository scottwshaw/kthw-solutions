# Provisioning

gcloud compute --project "centered-seat-178501" \
       ssh --zone "us-central1-f" controller0 --command \
       'kubectl create clusterrolebinding kubelet-bootstrap  --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap'

# exec $2++ on $1
function gcloudexec {
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" $1 --command "${@:2}"
}

# exec all of $2++ on $1
function gcloudexecall {
    for comnd in "${@:2}"; do
	gcloudexec $1 "${comnd}"
    done
}

# Provision the worker nodes

for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  'if [ ! -d "/var/lib/kubelet" ]; then sudo mkdir -p /var/lib/kubelet; fi' \
		  'if [ ! -d "/var/lib/kube-proxy" ]; then  sudo mkdir -p /var/lib/kube-proxy; fi'  \
		  'if [ ! -d "/var/lib/kubernetes" ]; then  sudo mkdir -p /var/lib/kubernetes; fi'  \
		  'if [ ! -d "/var/run/kubernetes" ]; then sudo mkdir -p /var/run/kubernetes; fi' \
		  'if [ -e "bootstrap.kubeconfig" ]; then sudo mv bootstrap.kubeconfig /var/lib/kubelet; fi' \
		  'if [ -e "kube-proxy.kubeconfig" ]; then sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy; fi' \
		  'if [ -e "ca.pem" ]; then sudo mv ca.pem /var/lib/kubernetes/; fi'
done


# Install Docker

for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  'wget https://get.docker.com/builds/Linux/x86_64/docker-1.12.6.tgz' \
		  'tar -xvf docker-1.12.6.tgz' \
		  'sudo cp docker/docker* /usr/bin/'
done

# Copy Docker config script and make it executable
for host in worker0 worker1 worker2; do
    gcloud compute scp config-docker.bash ${host}:~/
    gcloudexec ${host} 'chmod a+x ~/config-docker.bash'
done

# Execute the config script and start docker
for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  '~/config-docker.bash' \
		  'sudo systemctl daemon-reload' \
		  'sudo systemctl enable docker' \
		  'sudo systemctl start docker' \
		  'sudo docker version'
done
    
# Install Kubelet
for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  'sudo mkdir -p /opt/cni' \
		  'wget https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz' \
		  'sudo tar -xvf cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz -C /opt/cni' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kube-proxy' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubelet' \
		  'chmod +x kubectl kube-proxy kubelet' \
		  'sudo mv kubectl kube-proxy kubelet /usr/bin/'
done

# Copy Kubelet config script and make executeable
for host in worker0 worker1 worker2; do
    gcloud compute scp config-kubelet.bash ${host}:~/
    gcloudexec ${host} 'chmod a+x ~/config-kubelet.bash'
done

# Start Kubelet
for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  '~/config-kubelet.bash' \
		  'sudo systemctl daemon-reload' \
		  'sudo systemctl enable kubelet' \
		  'sudo systemctl start kubelet' \
		  'sudo systemctl status kubelet --no-pager'
done

# Copy Kube-proxy config script and make executeable
for host in worker0 worker1 worker2; do
    gcloud compute scp config-kube-proxy.bash ${host}:~/
    gcloudexec ${host} 'chmod a+x ~/config-kube-proxy.bash'
done

# Start Kube-proxy
for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  '~/config-kube-proxy.bash' \
		  'sudo systemctl daemon-reload' \
		  'sudo systemctl enable kube-proxy' \
		  'sudo systemctl start kube-proxy' \
		  'sudo systemctl status kube-proxy --no-pager'
done

# Approve TLS Certificate requests

gcloudexec controller0 'kubectl get csr'


