resource "aws_security_group" "Master-Linux" {
  name = "${var.cluster-name}-master-linux"
  tags {
        Name = "${var.cluster-name}-master-linux"
  }
  description = "master linux connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#All TCP to from gateway 
#All TCP to from nodes
#All ICMP to from nodes
#All ICMP to from gateway
#22 from bastion only 




resource "aws_security_group" "Gateway" {
  name = "${var.cluster-name}-gateway"
  tags {
        Name = "${var.cluster-name}-gateway"
  }
  description = "gateway node connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Node" {
  name = "${var.cluster-name}-node"
  tags {
        Name = "${var.cluster-name}-node"
  }
  description = "master node connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "0"
    to_port     = "65000"
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "Bastion-Linux" {
  name = "${var.cluster-name}-bastion-linux"
  tags {
        Name = "${var.cluster-name}-bastion-linux"
  }
  description = "bastion linux connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dockerproxy-Linux" {
  name = "${var.cluster-name}-dockerproxy-linux"
  tags {
        Name = "${var.cluster-name}-dockerproxy-linux"
  }
  description = "dockerproxy linux connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "Bastion-Win" {
  name = "${var.cluster-name}-bastion-win"
  tags {
        Name = "${var.cluster-name}-bastion-win"
  }
  description = "bastion win connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "3389"
    to_port     = "3389"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

