#!/bin/bash
echo "from https://balaskas.gr/blog/2022/08/31/creating-a-kubernetes-cluster-with-kubeadm-on-ubuntu-2204-lts/"
echo "notes:"
echo "https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network"
echo "https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model"
echo "https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"

echo "Tested to work with Ubuntu 22.04"
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
sleep 5

sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
sleep 1
sudo modprobe overlay
sudo modprobe br_netfilter
sleep 1
sudo lsmod | grep netfilter
sleep 1

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sleep 1
sudo sysctl --system

sleep 1
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf

sleep 1
curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-keyring.gpg

sleep 1
sudo apt-add-repository -y "deb https://download.docker.com/linux/ubuntu jammy stable"

sleep 5
sudo apt -y install containerd.io

sleep 1
containerd config default |
  sed 's/SystemdCgroup = false/SystemdCgroup = true/' |
  sudo tee /etc/containerd/config.toml

sleep 1
sudo systemctl restart containerd.service

sleep 1
sudo curl -sLo /etc/apt/trusted.gpg.d/kubernetes-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

sleep 1
sudo apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sleep 1
sudo apt install -y kubelet kubeadm kubectl

sleep 5
sudo systemctl daemon-reload
sudo systemctl restart kubelet

sleep 1
sudo kubeadm config images pull

sleep 5
sudo kubeadm init --image-repository=registry.k8s.io --pod-network-cidr 192.168.0.0/16

sleep 1
mkdir -p $HOME/.kube
sleep 1
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sleep 1
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 1
sudo chown $(id -u):$(id -g) $HOME/.kube/
ls -la $HOME/.kube/config
alias k="kubectl"

sleep 1
echo "Installing calico"
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
kubectl apply -f calico.yaml

sleep 1
kubectl cluster-info

sleep 5
kubectl get nodes -o wide
sleep 1
kubectl get pods -A -o wide
