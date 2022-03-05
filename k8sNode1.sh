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
echo "Joining Kube Master"
sudo kubeadm join 172.16.63.144:6443 --token 13f1qa.l4krmq6vaj6vw4lt --discovery-token-ca-cert-hash sha256:c980c85cbde18bff43d4bd24eb448180786faf3c7ece59bfb7026cf8da4c0c57
sleep 5


