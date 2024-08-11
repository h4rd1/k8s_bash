#!/bin/bash
#-----------------------------------------------------------------
# Скрипт для автоматической настройки Kubernetes и CRI-O
# Версия Kubernetes: 1.28
# Версия CRI-O: 1.23
#-----------------------------------------------------------------

# Установить имя хоста для Kubernetes Master
hostnamectl set-hostname 'k8s-master'


# Отключение SELinux и swap
setenforce 0
dnf update -y
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


# Загрузка необходимых модулей для Kubernetes
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF


sysctl --system
modprobe overlay
modprobe br_netfilter

# Установка CRI-O
export VERSION=1.23
curl -L -o /etc/dnf.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/dnf.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
dnf install -y cri-o
systemctl enable crio
systemctl start crio

# Установка Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF


dnf update -y
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
dnf clean all
systemctl enable --now kubelet
kubeadm config images pull


# Инициализация кластера
kubeadm init --pod-network-cidr=10.244.0.0/16
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml
#Если нужен будет nginx ingress просто раскоментировать 
#wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/do/deploy.yaml
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" > /etc/environment
export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
#kubectl create namespace ingress-nginx
kubectl apply -f calico.yaml
#kubectl apply -f deploy.yaml --namespace=ingress-nginx
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
