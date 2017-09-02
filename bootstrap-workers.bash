# Provisioning

gcloud compute --project "centered-seat-178501" \
       ssh --zone "us-central1-f" controller0 --command \
       'kubectl create clusterrolebinding kubelet-bootstrap  --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap'


# exec $2 on $1
function gcloudexec {
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" $1 --command '"${@:2}"'
}

# exec all of $2 on $1
function gcloudexecall {
    for comnd in "${@:2}"; do
	gcloudexec $1 ${comnd}
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

