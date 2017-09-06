#!/bin/bash
set -e


. ./gcloudexec.bash # define helper functions

# download and install etcd binaries
for host in controller-0 controller-1 controller-2; do
    gcloudexecall ${host} \
		  'wget https://github.com/coreos/etcd/releases/download/v3.2.6/etcd-v3.2.6-linux-amd64.tar.gz' \
		  'tar -xvf etcd-v3.2.6-linux-amd64.tar.gz' \
		  'sudo mv etcd-v3.2.6-linux-amd64/etcd* /usr/local/bin/' \
		  'if [ ! -d "/var/lib/etcd" ]; then sudo mkdir -p /var/lib/etcd; fi' \
		  'if [ ! -d "/etc/etcd" ]; then sudo mkdir -p /etc/etcd/; fi' \
		  'sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/'
done

# Copy the config and startup scripts to the controllers
for host in controller-0 controller-1 controller-2; do
  gcloud compute scp remote-exec/config-etcd.bash remote-exec/start-etcd.bash ${host}:~/
  gcloudexec ${host} 'chmod a+x config-etcd.bash start-etcd.bash'
done

# Execute the scripts
for host in controller-0 controller-1 controller-2; do
  gcloudexecall ${host} '~/config-etcd.bash' '~/start-etcd.bash'
done


# Check Status
for host in controller-0 controller-1 controller-2; do
    gcloudexec ${host} 'ETCDCTL_API=3 etcdctl member list'
done
