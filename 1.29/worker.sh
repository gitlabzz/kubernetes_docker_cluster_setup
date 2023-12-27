#!/bin/bash
echo "from https://balaskas.gr/blog/2022/08/31/creating-a-kubernetes-cluster-with-kubeadm-on-ubuntu-2204-lts/"
echo "notes:"
echo "https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network"
echo "https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model"
echo "https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"

echo "Tested to work with Ubuntu 22.04"

sudo apt update -y
sudo apt install iputils-ping -y
sudo apt install net-tools -y
sudo apt install vim -y
udo apt install ufw -
sudo ufw disable
sudo sh -c 'hostname=$(hostname) && ip=$(hostname -I | cut -d" " -f1) && echo "$ip $hostname\n172.16.236.134 master" >> /etc/hosts'

echo "Disable firewall"
sudo ufw disable
echo "Disable swap"
sudo swapoff -a
sleep 1
echo "Removing swap entry from fstab"
sudo sed -i '/swapfile/d' /etc/fstab

sleep 1
echo "installing gnupg2, apt-transport-https, ca-certificates, curl, software-properties-common"
sudo apt-get update && sudo apt-get install -y gnupg gnupg2 apt-transport-https ca-certificates curl software-properties-common lsb-release
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
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd

# Install kubeadm, kubelet and kubectl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sleep 2
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

sleep 1
sudo kubeadm config images pull

sleep 5
sudo kubeadm join 172.16.236.134:6443 --token m50q31.71521hwvwxtc7xv7 --discovery-token-ca-cert-hash sha256:968a019f2f57db29d38563459d89c190dc082c7a34455f7da21db2a2295c5113