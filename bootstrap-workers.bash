#Provisioning

kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap

# exec $2 on $1
function gcloudexec {
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" $1 --command $2
    exit
}

# exec all of $2 on $1
function gcloudexecall {
    for comnd in ${@:2}; do
	gcloudexec $1 ${comnd}
    done
    exit
}

for host in worker0 worker1 worker2; do
    gcloudexecall ${host} \
		  'if [ ! -d "/var/lib/kubelet" ]; then sudo mkdir -p /var/lib/kubelet; fi' \
		  'sudo mv token.csv /var/lib/kubernetes' \
		  'sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/'
done
