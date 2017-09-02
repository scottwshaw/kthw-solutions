# Configure tokens

for host in controller0 controller1 controller2; do
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'if [ ! -d "/var/lib/kubernetes" ]; then sudo mkdir -p /var/lib/kubernetes; fi'
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'sudo mv token.csv /var/lib/kubernetes'
  gcloud compute --project "centered-seat-178501" \
  	 ssh --zone "us-central1-f" ${host} --command \
	 'sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/'
done

# Download and install the Kubernetes controller binaries

for host in controller0 controller1 controller2; do
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kube-apiserver'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kube-controller-manager'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kube-scheduler'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'wget https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl'
    gcloud compute --project "centered-seat-178501" \
	   ssh --zone "us-central1-f" ${host} --command \
	   'sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/'
done

# Copy the config and startup scripts to the controllers
for host in controller0 controller1 controller2; do
  gcloud compute scp config-api-server.bash start-api-server.bash ${host}:~/
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'chmod a+x config-api-server.bash start-api-server.bash'
done

# Execute the scripts
for host in controller0 controller1 controller2; do
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/config-api-server.bash'
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/start-api-server.bash'
done

# Copy the config and startup scripts for controller manager
for host in controller0 controller1 controller2; do
  gcloud compute scp config-controller-manager.bash start-controller-manager.bash ${host}:~/
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'chmod a+x config-controller-manager.bash start-controller-manager.bash'
done

# Execute the scripts
for host in controller0 controller1 controller2; do
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/config-controller-manager.bash'
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/start-controller-manager.bash'
done

# Copy the config and startup scripts for scheduler
for host in controller0 controller1 controller2; do
  gcloud compute scp config-scheduler.bash start-scheduler.bash ${host}:~/
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'chmod a+x config-scheduler.bash start-scheduler.bash'
done

# Execute the scripts
for host in controller0 controller1 controller2; do
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/config-scheduler.bash'
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 '~/start-scheduler.bash'
done


# Verify
for host in controller0 controller1 controller2; do
  gcloud compute --project "centered-seat-178501" \
	 ssh --zone "us-central1-f" ${host} --command \
	 'kubectl get componentstatuses'
done

gcloud compute http-health-checks create kube-apiserver-health-check \
  --description "Kubernetes API Server Health Check" \
  --port 8080 \
  --request-path /healthz

gcloud compute target-pools create kubernetes-target-pool \
  --http-health-check=kube-apiserver-health-check \
  --region us-central1

gcloud compute target-pools add-instances kubernetes-target-pool \
       --instances controller0,controller1,controller2

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region us-central1 \
  --format 'value(name)')

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
  --address ${KUBERNETES_PUBLIC_ADDRESS} \
  --ports 6443 \
  --target-pool kubernetes-target-pool \
  --region us-central1
