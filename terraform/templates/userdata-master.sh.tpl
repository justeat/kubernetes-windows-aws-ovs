#!/bin/bash

cat >/startup.sh <<EOL
#!/bin/bash
export S3_BUCKET=${bucket_name}
export K8S_VERSION=1.7.3
export TUNNEL_MODE=geneve
export LOCAL_IP=\$(ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print \$3}')
export MASTER_IP=\$(ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print \$3}')
export EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
export EC2_REGION="`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
export HOSTNAME=\$(hostname).\$EC2_REGION.compute.internal
export K8S_VERSION=${k8s_version}
export K8S_POD_SUBNET=${k8s_pod_subnet}
export K8S_NODE_POD_SUBNET=${k8s_node_pod_subnet}
export K8S_SERVICE_SUBNET=${k8s_service_subnet}
export K8S_API_SERVICE_IP=${k8s_api_service_ip}
export K8S_DNS_VERSION=${k8s_dns_version}
export K8S_DNS_SERVICE_IP=${k8s_dns_service_ip}
export K8S_DNS_DOMAIN=${k8s_dns_domain}
export ETCD_VERSION=${etcd_version}
export MASTER_INTERNAL_IP=${master_internal_ip}
export PUBLICDNS="api.${public_dns}"

echo "ovn setup"

echo "open v switch setup"
sleep 5 
echo "setting connections"
ovn-nbctl set-connection ptcp:6641
ovn-sbctl set-connection ptcp:6642
echo "connections set"

ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:\$MASTER_IP:6642" external_ids:ovn-nb="tcp:\$MASTER_IP:6641" external_ids:ovn-encap-ip="\$LOCAL_IP" external_ids:ovn-encap-type="\$TUNNEL_MODE"

ovs-vsctl get Open_vSwitch . external_ids
echo "--- north and southbound"
echo \$$(ovn-sbctl show)
echo \$$(ovn-nbctl show)
echo "---"

cd ~/kubernetes-ovn-heterogeneous-cluster/master
rm -rf tmp
mkdir tmp
cp -R make-certs openssl.cnf kubedns-* manifests systemd tmp/

# The following is needed for now, because OVS can't route from pod network to node.

sed -i"*" "s|__K8S_VERSION__|\$K8S_VERSION|g" tmp/manifests/*.yaml
sed -i"*" "s|__K8S_VERSION__|\$K8S_VERSION|g" tmp/systemd/kubelet.service
sed -i"*" "s|__ETCD_VERSION__|\$ETCD_VERSION|g" tmp/systemd/etcd3.service
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/manifests/*.yaml
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/openssl.cnf
sed -i"*" "s|__MASTER_INTERNAL_IP__|\$MASTER_INTERNAL_IP|g" tmp/manifests/*.yaml
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/systemd/kubelet.service
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/make-certs
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/openssl.cnf
sed -i"*" "s|__K8S_DNS_PUBLICDOMAIN__|\$PUBLICDNS|g" tmp/openssl.cnf
sed -i"*" "s|__K8S_API_SERVICE_IP__|\$K8S_API_SERVICE_IP|g" tmp/openssl.cnf
sed -i"*" "s|__K8S_POD_SUBNET__|\$K8S_POD_SUBNET|g" tmp/manifests/*.yaml
sed -i"*" "s|__K8S_SERVICE_SUBNET__|\$K8S_SERVICE_SUBNET|g" tmp/manifests/*.yaml
sed -i"*" "s|__K8S_DNS_SERVICE_IP__|\$K8S_DNS_SERVICE_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__K8S_DNS_DOMAIN__|\$K8S_DNS_DOMAIN|g" tmp/systemd/kubelet.service
sed -i"*" "s|__K8S_DNS_SERVICE_IP__|\$K8S_DNS_SERVICE_IP|g" tmp/kubedns-service.yaml
sed -i"*" "s|__K8S_DNS_VERSION__|\$K8S_DNS_VERSION|g" tmp/kubedns-deployment.yaml
sed -i"*" "s|__K8S_DNS_DOMAIN__|\$K8S_DNS_DOMAIN|g" tmp/*.*

cp -R tmp/systemd/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable etcd3
systemctl start etcd3

cd tmp
chmod +x make-certs
./make-certs
cd ..

mkdir -p /etc/kubernetes
cp -R tmp/manifests /etc/kubernetes/

systemctl enable kubelet
systemctl start kubelet

kubectl config set-cluster default-cluster --server=https://\$MASTER_IP --certificate-authority=/etc/kubernetes/tls/ca.pem
kubectl config set-credentials default-admin --certificate-authority=/etc/kubernetes/tls/ca.pem --client-key=/etc/kubernetes/tls/admin-key.pem --client-certificate=/etc/kubernetes/tls/admin.pem
kubectl config set-context local --cluster=default-cluster --user=default-admin
kubectl config use-context local

while true; do
  str=\$$(kubectl get nodes)
  echo Output: \$str
  if [[ \$str =~ "SchedulingDisabled" ]]; then
    break
  fi
  sleep 1
done
echo "get token"
export TOKEN_NAME=\$$(kubectl get secrets | grep default | cut -f1 -d ' ')
echo "TOKEN_NAME: \$TOKEN_NAME"
export TOKEN=\$$(kubectl describe secret \$TOKEN_NAME | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
echo "TOKEN \$TOKEN"

ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="https://\$MASTER_IP" external_ids:k8s-api-token="\$TOKEN"

ln -fs /etc/kubernetes/tls/ca.pem /etc/openvswitch/k8s-ca.crt

mkdir -p /opt/cni/bin && cd /opt/cni/bin
curl -Lskj -o cni.tar.gz https://github.com/containernetworking/cni/releases/download/v0.4.0/cni-v0.4.0.tgz
tar zxf cni.tar.gz
rm -f cni.tar.gz

cd ~
git clone https://github.com/owain-je/ovn-kubernetes.git
cd ovn-kubernetes

pip install --upgrade --prefix=/usr/local --ignore-installed .

echo "sleeping"
sleep 20 
echo "slept"

echo " ovn-k8s-overlay master-init --cluster-ip-subnet=\"\$K8S_POD_SUBNET\" --master-switch-subnet=\"\$K8S_NODE_POD_SUBNET\" --node-name=\"\$HOSTNAME\" "

ovn-k8s-overlay master-init \
  --cluster-ip-subnet="\$K8S_POD_SUBNET" \
  --master-switch-subnet="\$K8S_NODE_POD_SUBNET" \
  --node-name="\$HOSTNAME"

echo "ovn-k8s-overlay master init exit: \$?"

systemctl enable ovn-k8s-watcher
systemctl start ovn-k8s-watcher

cd ~/kubernetes-ovn-heterogeneous-cluster/master
kubectl create -f tmp/kubedns-deployment.yaml
kubectl create -f tmp/kubedns-service.yaml

echo "uploading files to s3"

echo \$MASTER_IP > /masterip
aws s3 cp /masterip s3://\$S3_BUCKET/masterip
aws s3 cp /etc/kubernetes/tls/ca-key.pem s3://\$S3_BUCKET/tls/ca-key.pem
aws s3 cp /etc/kubernetes/tls/ca.pem s3://\$S3_BUCKET/tls/ca.pem
aws s3 cp /etc/kubernetes/tls/admin-key.pem s3://\$S3_BUCKET/admin/admin-key.pem
aws s3 cp /etc/kubernetes/tls/admin.pem s3://\$S3_BUCKET/admin/admin.pem
aws s3 cp /root/.kube/config s3://\$S3_BUCKET/admin/config

env

echo "--- north and southbound"
echo \$$(ovn-sbctl show)
echo \$$(ovn-nbctl show)
echo "---"


cat > /etc/rc.local <<AOL
#!/bin/sh -e
#
exit 0
AOL

chmod 755 /etc/rc.local

EOL

chmod 755 /startup.sh

export K8S_VERSION=1.7.3
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


apt install awscli -y 

cat >/etc/rc.local <<EOL
#!/bin/sh -e
#
sudo /startup.sh > /var/log/startup.log 2>&1
exit 0
EOL

chmod 755 /etc/rc.local

echo "rebooting"
reboot
