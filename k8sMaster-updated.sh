#!/bin/bash
echo "Tested to work with Ubuntu 20.04"
echo "Disable firewall"
sudo ufw disable
echo "Disable swap"
sudo swapoff -a
sleep 1
echo "Removing swap entry from fstab"
sudo sed -i '/swapfile/d' /etc/fstab

sleep 1
echo "installing gnupg2, apt-transport-https, ca-certificates, curl, software-properties-common"
sudo apt-get update && sudo apt-get install -y gnupg2 apt-transport-https ca-certificates curl software-properties-common

echo "Install Docker"
sleep 1
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
sudo apt-get install -y docker.io

echo "Enabling docker service"
sudo systemctl enable --now docker.service

echo "adding user to docker group"
sudo usermod -aG docker ${USER}

echo "Preparing to install kubeadm, kubelet, and kubectl"

echo "add repository"
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

echo "adding apt-key"
sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"

sudo apt-get update

echo "Installing kubeadm, kubelet, and kubectl"
sudo apt-get install -y kubeadm=1.23.4-00 kubelet=1.23.4-00 kubectl=1.23.4-00

echo "holding kubeadm, kubelet, and kubectl, so that don't update automatically."
sudo apt-mark hold kubelet kubeadm kubectl

sleep 2

sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

sleep 2
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl restart kubelet

sleep 1

echo "initialising the cluster"
sudo kubeadm init --kubernetes-version 1.23.4 --pod-network-cidr 192.168.0.0/16

sleep 5

echo "Just running step as expained in kubeadm init completion"

mkdir -p $HOME/.kube
sleep 2
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sleep 2
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 2
sudo chown $(id -u):$(id -g) $HOME/.kube/

echo "Applying cloud.weave.works network plugin"
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo
sleep 3
echo "Running kubectl get nodes, we should see this node in the output below:"
echo
kubectl get nodes
echo
echo "Script finished. Move to the next step"
