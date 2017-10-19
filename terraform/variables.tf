variable "cluster-name" {
  default = "pluto"
}

variable "dns-zone" {
  default = "example.com
}

variable "region" {
  default = "eu-west-1"
}

variable "AmiLinux" {
  type = "map"
  default = {
    eu-west-2 = "ami-785db401"
    eu-central-1 = "ami-1e339e71"
    eu-west-1 = "ami-785db401"
  }
  description = ""
}
variable "AmiWindows" {
  type = "map"
  default = {
    eu-west-2 = "ami-70e5f414"
    eu-central-1 = "ami-331eb05c"
    eu-west-1 = "ami-4763923e"
  }
  description = ""
}

variable "aws_access_key" {
  default = ""
  description = "the user aws access key"
}
variable "aws_secret_key" {
  default = ""
  description = "the user aws secret key"
}

variable "k8s_version" {
  default = "1.7.3"
}

variable "k8s_dns_version" {
  default = "1.13.0"
}

variable "k8s_dns_domain" {
  default = "cluster.local"
}
variable "etcd_version" {
  default = "3.1.1"
}

variable "vpc-fullcidr" {
  default = "10.5.4.0/22"
  description = "the vpc cdir"
}
variable "Subnet-Public-AzA-CIDR" {
  default = "10.5.5.0/24"
  description = "the cidr of the subnet"
}

variable "Subnet-Master-CIDR" {
  default = "10.5.6.0/24"
  description = "the cidr of the subnet"
}

variable "Subnet-Nodes-CIDR" {
  default = "10.5.7.0/24"
  description = "the cidr of the subnet"
}

variable "k8s_pod_subnet" {
  default = "192.168.0.0/16"
}
variable "k8s_pod_subnet_prefix" {
  default = "192.168"
}
variable "k8s_pod_subnet_network" {
  default = "0.0./16"
}

variable "k8s_node_pod_subnet" {
  default = "192.168.1.0/24"
}

variable "master_internal_ip" {
  default = "192.168.1.2"
}

variable "k8s_service_subnet" {
  default = "172.16.0.0/16"
}
variable "k8s_api_service_ip" {
  default = "172.16.0.1"
}
variable "k8s_dns_service_ip" {
  default = "172.16.0.10"
}

variable "core-availability-zone" {
  default = "eu-west-1b"
  description = "main availability zone" 
}

variable "DnsZoneName" {
  default = "cluster.internal"
  description = "the internal dns name"
}

variable "bastion-linux-instance-type" {
  default = "t2.micro"
  description = "linux bastion instance type"
}

variable "bastion-windows-instance-type" {
  default = "t2.medium"
  description = "windows bastion instance type"
}

variable "master-linux-instance-type" {
  default = "t2.medium"
  description = "linux master node instance type"
}

variable "gateway-linux-instance-type" {
  default = "t2.medium"
  description = "linux gateway node instance type"
}

variable "node-linux-instance-type" {
  default = "t2.medium"
  description = "linux node instance type"
}

variable "node-windows-instance-type" {
  default = "t2.medium"
  description = "linux windows node instance type"
}

variable "dockerproxy-linux-instance-type" {
  default = "t2.medium"
  description = "linux dockerproxy instance type"
}

variable "node-linux-asg-max-size" {
  default = "1"
  description = "node linux autoscale group max size"
}
variable "node-linux-asg-min-size" {
  default = "1"
  description = "node linux autoscale group min size"
}
variable "node-linux-asg-desired-capacity" {
  default = "1"
  description = "node linux autoscale desired capacity"
}
variable "node-linux-lc-volume-type" {
  default = "gp2"
  description = "node linux volume type"
}
variable "node-linux-lc-volume-size" {
  default = "150"
  description = "node linux volume size"
}

variable "node-windows-asg-max-size" {
  default = "1"
  description = "node windows autoscale group max size"
}
variable "node-windows-asg-min-size" {
  default = "1"
  description = "node windows autoscale group min size"
}
variable "node-windows-asg-desired-capacity" {
  default = "1"
  description = "node windows autoscale desired capacity"
}
variable "node-windows-lc-volume-type" {
  default = "gp2"
  description = "node windows volume type"
}
variable "node-windows-lc-volume-size" {
  default = "150"
  description = "node windows volume size"
}





