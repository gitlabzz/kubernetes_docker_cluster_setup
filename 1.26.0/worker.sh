#!/bin/bash
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
sudo kubeadm join 172.16.240.137:6443 --token 5dnzeg.6876ug1j8v4o9hhh --discovery-token-ca-cert-hash sha256:341a7b737741d619695ad3fbf6fdfb54a0a72af722222f78b7e1fe97105e23c4