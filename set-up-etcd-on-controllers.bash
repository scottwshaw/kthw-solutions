# Create etcd directoris and copy certs

for host in controller0 controller1 controller2; do
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'if [ ! -d "/etc/etcd" ]; then sudo mkdir -p /etc/etcd/; fi'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/'
done

# download and install etcd binaries

for host in controller0 controller1 controller2; do
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'wget https://github.com/coreos/etcd/releases/download/v3.1.4/etcd-v3.1.4-linux-amd64.tar.gz'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'tar -xvf etcd-v3.1.4-linux-amd64.tar.gz'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'sudo mv etcd-v3.1.4-linux-amd64/etcd* /usr/bin/'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
    	   'if [ ! -d "/var/lib/etcd" ]; then sudo mkdir -p /var/lib/etcd; fi'
done

# Copy the config and startup scripts to the controllers
for host in controller0 controller1 controller2; do
  gcloud compute scp config-etcd.bash start-etcd.bash ${host}:~/
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'chmod a+x config-etcd.bash start-etcd.bash'
done

# Execute the scripts
for host in controller0 controller1 controller2; do
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/config-etcd.bash'
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/start-etcd.bash'
done

# Test etcd cluster health
gcloud compute --project "centered-seat-178501" \
       ssh --zone "us-central1-f" ${host} --command \
       'sudo etcdctl --ca-file=/etc/etcd/ca.pem --cert-file=/etc/etcd/kubernetes.pem --key-file=/etc/etcd/kubernetes-key.pem cluster-health'








