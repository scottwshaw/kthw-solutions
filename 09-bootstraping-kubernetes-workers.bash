#!/bin/bash
set -e

. ./gcloudexec.bash

# Install cri-o dependencies
for host in worker-0 worker-1 worker-2; do
    gcloudexecall ${host} \
		  'sudo add-apt-repository -y ppa:alexlarsson/flatpak' \
		  'sudo apt-get update' \
		  'sudo apt-get install -y socat libgpgme11 libostree-1-1'
done

# Download and install k8 worker binaries

for host in worker-0 worker-1 worker-2; do
    gcloudexecall ${host} \
		  'sudo mkdir -p /opt/cni' \
		  'wget https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz' \
		  'wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc4/runc.amd64' \
		  'wget https://storage.googleapis.com/kubernetes-the-hard-way/crio-amd64-v1.0.0-beta.0.tar.gz' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kubectl' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kube-proxy' \
		  'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.4/bin/linux/amd64/kubelet' \
		  'if [ ! -d "/etc/containers" ]; then sudo mkdir -p /etc/containers; fi' \
		  'if [ ! -d "/etc/cni/net.d" ]; then sudo mkdir -p /etc/cni/net.d; fi' \
		  'if [ ! -d "/etc/crio" ]; then sudo mkdir -p /etc/crio; fi' \
		  'if [ ! -d "/opt/cni/bin" ]; then sudo mkdir -p /opt/cni/bin; fi' \
		  'if [ ! -d "/usr/local/libexec/crio" ]; then sudo mkdir -p /usr/local/libexec/crio; fi' \
		  'if [ ! -d "/var/lib/kubelet" ]; then sudo mkdir -p /var/lib/kubelet; fi' \
		  'if [ ! -d "/var/lib/kube-proxy" ]; then  sudo mkdir -p /var/lib/kube-proxy; fi'  \
		  'if [ ! -d "/var/lib/kubernetes" ]; then  sudo mkdir -p /var/lib/kubernetes; fi'  \
		  'if [ ! -d "/var/run/kubernetes" ]; then sudo mkdir -p /var/run/kubernetes; fi' \
		  'sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/' \
		  'tar -xvf crio-amd64-v1.0.0-beta.0.tar.gz' \
		  'chmod +x kubectl kube-proxy kubelet runc.amd64' \
		  'sudo mv runc.amd64 /usr/local/bin/runc' \
		  'sudo mv crio crioctl kpod kubectl kube-proxy kubelet /usr/local/bin/' \
		  'sudo mv conmon pause /usr/local/libexec/crio/'
done

# Config CNI networking
for host in worker-0 worker-1 worker-2; do
    gcloud compute scp remote-exec/config-cni-networking.bash ${host}:~/
    gcloudexecall ${host} \
		  'chmod a+x ~/config-cni-networking.bash' \
                  '~/config-cni-networking.bash'
done

# Config CRI-O runtime
for host in worker-0 worker-1 worker-2; do
    gcloudexecall ${host} \
		  'sudo mv crio.conf seccomp.json /etc/crio/' \
		  'sudo mv policy.json /etc/containers/'
    gcloud compute scp remote-exec/config-cri-o-runtime.bash ${host}:~/
    gcloudexecall ${host} \
		  'chmod a+x ~/config-cri-o-runtime.bash' \
                  '~/config-cri-o-runtime.bash'
done
# Config the kubelet
for host in worker-0 worker-1 worker-2; do
    gcloudexecall ${host} \
		  'sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/' \
		  'sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig' \
		  'sudo mv ca.pem /var/lib/kubernetes/'
    gcloud compute scp remote-exec/config-kubelet.bash ${host}:~/
    gcloudexecall ${host} \
		  'chmod a+x ~/config-kubelet.bash' \
                  '~/config-kubelet.bash'
done

# Config kube-proxy

for host in worker-0 worker-1 worker-2; do
    gcloudexec ${host} 'sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig'
    gcloud compute scp remote-exec/config-kube-proxy.bash ${host}:~/
    gcloudexecall ${host} \
		  'chmod a+x ~/config-kube-proxy.bash' \
                  '~/config-kube-proxy.bash'
done

# Start the worker services
for host in worker-0 worker-1 worker-2; do
    gcloudexecall ${host} \
		  'sudo mv crio.service kubelet.service kube-proxy.service /etc/systemd/system/' \
		  'sudo systemctl daemon-reload' \
		  'sudo systemctl enable crio kubelet kube-proxy' \
		  'sudo systemctl start crio kubelet kube-proxy'
done

gcloudexecall controller-0 'kubectl get nodes'



    
    

