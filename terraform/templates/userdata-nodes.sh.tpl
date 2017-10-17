#!/bin/bash

cat >/startup.sh <<EOL
#!/bin/bash
S3_BUCKET=${bucket_name}
export TUNNEL_MODE=geneve
export LOCAL_IP=\$(ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print \$3}')
export LAST_OCTET=\$(ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print \$3}' | cut -d . -f 4)
export EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
export EC2_REGION="`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
export HNAME=`hostname`
export HOSTNAME="\$HNAME.\$EC2_REGION.compute.internal"
export K8S_VERSION=${k8s_version}
export K8S_POD_SUBNET=${k8s_pod_subnet}
export K8S_NODE_POD_SUBNET=${k8s_pod_subnet_prefix}.\$LAST_OCTET.0/24
export K8S_DNS_SERVICE_IP=${k8s_dns_service_ip}
export K8S_DNS_DOMAIN=${k8s_dns_domain}

env

groupadd kube-cert

apt install -y awscli 

#Needs to wait until gw ip is there, to avoid race condition with master and gw nodes
until aws s3 cp s3://\$S3_BUCKET/gwip /gwip
do
  echo "gw ip not available"
  sleep 5 
done
aws s3 cp s3://\$S3_BUCKET/masterip /masterip
aws s3 cp s3://\$S3_BUCKET/tls/ca-key.pem /etc/kubernetes/tls/ca-key.pem 
aws s3 cp s3://\$S3_BUCKET/tls/ca.pem /etc/kubernetes/tls/ca.pem 

export MASTER_IP=\$$(< /masterip)

echo "MASTER_IP \$MASTER_IP"
echo "LOCAL_IP \$LOCAL_IP"
echo "K8S_NODE_POD_SUBNET \$K8S_NODE_POD_SUBNET"


ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:\$MASTER_IP:6642" \
  external_ids:ovn-nb="tcp:\$MASTER_IP:6641" \
  external_ids:ovn-encap-ip="\$LOCAL_IP" \
  external_ids:ovn-encap-type="\$TUNNEL_MODE"

ovs-vsctl get Open_vSwitch . external_ids

cd ~/kubernetes-ovn-heterogeneous-cluster/worker/linux

rm -rf tmp
mkdir tmp
cp -R ../make-certs ../openssl.cnf ../kubeconfig.yaml systemd tmp/
# so a bit of a hacky way to get a unique subnet address , works for only 254 nodes right....

sed -i"*" "s|__K8S_VERSION__|\$K8S_VERSION|g" tmp/systemd/kubelet.service
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/openssl.cnf
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/kubeconfig.yaml
sed -i"*" "s|__LOCAL_IP__|\$LOCAL_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__LOCAL_IP__|\$LOCAL_IP|g" tmp/openssl.cnf
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/systemd/kubelet.service
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/make-certs
sed -i"*" "s|__K8S_DNS_SERVICE_IP__|\$K8S_DNS_SERVICE_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__K8S_DNS_DOMAIN__|\$K8S_DNS_DOMAIN|g" tmp/systemd/kubelet.service

cd tmp
chmod +x make-certs
./make-certs
cd ..

mkdir -p /etc/kubernetes/

cp tmp/kubeconfig.yaml /etc/kubernetes/

cp -R tmp/systemd/*.service /etc/systemd/system/
systemctl daemon-reload

curl -Lskj -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v\$K8S_VERSION/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

kubectl config set-cluster default-cluster --server=https://\$MASTER_IP --certificate-authority=/etc/kubernetes/tls/ca.pem
kubectl config set-credentials default-admin --certificate-authority=/etc/kubernetes/tls/ca.pem --client-key=/etc/kubernetes/tls/node-key.pem --client-certificate=/etc/kubernetes/tls/node.pem
kubectl config set-context local --cluster=default-cluster --user=default-admin
kubectl config use-context local
echo "--- get nodes "
kubectl get nodes
kubectl get secrets
echo "---"

echo "get token"
export TOKEN_NAME=\$$(kubectl get secrets | grep default | cut -f1 -d ' ')
echo "TOKEN_NAME: \$TOKEN_NAME"
export TOKEN=\$$(kubectl describe secret \$TOKEN_NAME | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
echo "TOKEN \$TOKEN"

ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="https://\$MASTER_IP" external_ids:k8s-api-token="\$TOKEN"
ln -fs /etc/kubernetes/tls/ca.pem /etc/openvswitch/k8s-ca.crt
echo "TOKEN \$TOKEN" 

mkdir -p /opt/cni/bin && cd /opt/cni/bin
curl -Lskj -o cni.tar.gz https://github.com/containernetworking/cni/releases/download/v0.4.0/cni-v0.4.0.tgz
tar zxf cni.tar.gz
rm -f cni.tar.gz

cd ~
git clone https://github.com/openvswitch/ovn-kubernetes
cd ovn-kubernetes
pip install --upgrade --prefix=/usr/local --ignore-installed .

ovn-k8s-overlay minion-init --cluster-ip-subnet="\$K8S_POD_SUBNET" --minion-switch-subnet="\$K8S_NODE_POD_SUBNET" --node-name="\$HOSTNAME"


systemctl enable kubelet
systemctl start kubelet

cat > /etc/rc.local <<AOL
#!/bin/sh -e
#
exit 0
AOL

chmod 755 /etc/rc.local

EOL

chmod 755 /startup.sh

export K8S_VERSION={$k8s_version}
export S3_BUCKET=${bucket_name}

apt update -y
apt-get -y install  python-minimal python-six

curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > sudo tee /etc/apt/sources.list.d/docker.list

apt update -y
echo "install docker"
apt install -y docker.io dkms

cd ~
git clone https://github.com/owain-je/kubernetes-ovn-heterogeneous-cluster.git
cd kubernetes-ovn-heterogeneous-cluster/deb

dpkg -i openvswitch-common_2.7.2-1_amd64.deb \
openvswitch-datapath-dkms_2.7.2-1_all.deb \
openvswitch-switch_2.7.2-1_amd64.deb \
ovn-common_2.7.2-1_amd64.deb \
ovn-central_2.7.2-1_amd64.deb \
ovn-docker_2.7.2-1_amd64.deb \
ovn-host_2.7.2-1_amd64.deb \
python-openvswitch_2.7.2-1_all.deb

echo vport_geneve >> /etc/modules-load.d/modules.conf

curl -Lskj -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v$K8S_VERSION/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

apt install -y python-pip
pip install --upgrade pip
apt install -y awscli 

cat >/etc/rc.local <<EOL
#!/bin/sh -e
#
sudo /startup.sh > /var/log/startup.log 2>&1
exit 0
EOL

chmod 755 /etc/rc.local

mkdir -p /etc/kubernetes/tls

echo "rebooting"
reboot

