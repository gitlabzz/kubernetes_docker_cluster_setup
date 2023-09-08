#!/bin/bash
echo "Post Installation setup"

kubectl label nodes minion1 name=first
kubectl label nodes minion2 name=second

source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

### Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version

source <(helm completion bash)
echo "source <(helm completion bash)" >> ~/.bashrc

### Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.3/config/manifests/metallb-native.yaml
sleep 10

cat <<EOF | metal-lb-ip-range.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.16.240.240-172.16.240.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF

kubectl apply -f metal-lb-ip-range.yaml

### Install Nginx Ingress Using Helm
echo "https://kubernetes.github.io/ingress-nginx/deploy/"
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace
sleep 30
helm list -A
kubectl -n ingress-nginx get all
echo "Ingress Controller Type: LoadBalancer External IP: 172.16.240.240"
#echo "172.16.240.240	nginx.example.com" | sudo tee -a /etc/hosts


### NFS Dynamic Provisioning Setup
echo "Setup dynamic NFS provisioning in Kubernetes with Helm 3"
echo "https://kamrul.dev/setup-dynamic-nfs-provisioning-in-kubernetes-with-helm-3/"
echo "Youtube: https://www.youtube.com/watch?v=AavnQzWDTEk"
echo "Github: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner"
echo "SIG: https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
echo "Kubernetes Special Interest Groups: https://github.com/orgs/kubernetes-sigs/repositories"

### Setup
echo "NFS Server - master"
sudo ufw disable
sudo apt-get install nfs-kernel-server net-tools openssh-server -y
mkdir /home/dev/nfs_share
chmod -R 777 /home/dev/nfs_share
sudo chown nobody:nogroup /home/dev/nfs_share

sudo tee /etc/exports <<EOF
/home/dev/nfs_share    *(fsid=0,rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure)
EOF

sudo exportfs -a
sudo exportfs -rav
sudo systemctl restart nfs-server
sudo systemctl status nfs-server
sudo systemctl enable nfs-server

sleep 10

# Install NFS Provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=master --set nfs.path=/mnt/hgfs/tmp/nfs_share -n nfs-provisioner --create-namespace
sleep 10

# Make NFS Provisioner default storage class
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Install Local Path Provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

echo "Run following on minions"
echo "sudo mkdir -p /opt/local-path-provisioner"
echo "sudo chmod -R 777 /opt/local-path-provisioner"
echo "sudo chown nobody:nogroup /opt/local-path-provisioner"

# Metrics Server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server --set apiService.insecureSkipTLSVerify=true
sleep 10
echo "Patch Metrics Server for worker nodes certificates SAN issue"
#https://github.com/kubernetes-sigs/metrics-server/issues/196
kubectl -n default patch deployment metrics-server --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]]'
kubectl -n default rollout restart deployment metrics-server

# Install yq
VERSION=v4.27.5 && BINARY=yq_linux_amd64
sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
