## Kubernetes on windows in aws using ovn ##

This is some terraform to spin up a kubernetes cluster with windows nodes running on aws. this is based on the work examples to run in google 

[https://github.com/apprenda/kubernetes-ovn-heterogeneous-cluster](https://github.com/apprenda/kubernetes-ovn-heterogeneous-cluster)

With many thanks to:

- Paulo Pires [https://github.com/pires](https://github.com/pires)
- Alin Balutoiu [https://github.com/alinbalutoiu](https://github.com/alinbalutoiu)
- Alin Serdean [https://github.com/aserdean](https://github.com/aserdean)

This implementation will spin up a few ec2 instances. 

- Master node
- linux node 
- windows node 
- linux bastion node 
- windows bastion node
- gateway node  


# Setup 

1. Download the git repository 
2. You will need to have an ssh key pair available locally, use ssh-keygen to create one if you don't have a keypair you which to use. The public key must be copied into the file **keys.tf** 
2. Change to the terraform directory 
3. `terraform plan` 
4. `terraform apply`

This will set up a cluster which will obviously take a few minutes especially for the windows node. 

#Variables file 

in the terraform folder there is a variables.tf file , here are all the options to configure various aspects of the Custer. There is some duplication which I have not scripted out as this is just proof of concept code. PR's welcome 

- *cluster-name* is the name for the cluster 
- *dns-zone* is the dns zone that will be used host cluster public addresses
- *vpc-fullcidr*  is used to define the network address space of the VPC 
- *Subnet-Public-AzA-CIDR* is used to define the subnet for the public subnet 
- *Subnet-Master-CIDR*  is a subnet used for the master node(s)
- *Subnet-Nodes-CIDR* is the subnet used for the linux and windows nodes 
- *k8s_pod_subnet* is the address space used for pods 
- *k8s_pod_subnet_prefix* needs to be the first 2 octets of the k8s_pod_subnet
- *k8s_pod_subnet_network* needs to be the last 2 octects of the k8s_pod_subnet network
- *master_internal_ip* will be the ip address of the master pod 
- *k8s_service_subnet* is the address space for kubernetes services 
- *k8s_api_service_ip* is the address of the kubernetes service 
- *k8s_dns_service_ip* is the address of the DNS service
- *core-availability-zone* is the AZ which will be used for the cluster 

The rest of the variables should be self explanatory 
   

# Setting up kubectl locally 

you can use kubectl on any of the master or k8s nodes, local setup can be done by getting 3 files from the generated s3 bucket , which will have the name:

 *"${var.cluster-name}-k8s-state"*


    aws s3 cp s3:\\<bucket>\admin\admin-key.pem .
    aws s3 cp s3:\\<bucket>\admin\admin.pem .
    aws s3 cp s3:\\<bucket>\tls\ca.pem .
    
To use kubectl locally on your desktop you will need to create a config file in your home drive in a .kube folder 

    mkdir ~/.kube


```yaml 
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority: <homepath>\.kube\ca.pem
    server: https://api.<clustername>.<dns zone>
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-admin
  name: local
current-context: local
users:
- name: default-admin
  user:
    client-certificate: <homepath>\.kube\admin.pem
    client-key: <homepath>\.kube\admin-key.pem
```
# Network Setup 

The network configuration is 2 bastion nodes , one for linux and one for windows with public IP addresses 

# load balancers 

There are 2 elastic load balancers one for the API and one for supporting ingress using NodePort services, this points to the gateway node. 

#ssh Bastion host 

here is an example ssh config file if you want to ssh into the bastion nodes via ip address , 

ssh config file example which you store in your directory

 *< home >/.ssh/config *  


    Host k8s
      ForwardAgent yes
      Hostname <bastion host dns name>
      user ubuntu
      IdentityFile <path to ssh private key>
    
    Host 10.221.* 
      ProxyCommand ssh -W %h:%p k8s 
      StrictHostKeyChecking no
      User ubuntu
      IdentityFile  <path to ssh private key>



#RDP Bastion 


To RDP into the windows hosts you will need to use the bastion jumpbox. in the console get the public DNS address of the bastion host, and the AWS defined administrator password.  

