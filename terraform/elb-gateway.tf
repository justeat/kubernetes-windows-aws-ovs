resource "aws_security_group" "elb" {
  name        = "${var.cluster-name}-elb-gateway"
  description = "${var.cluster-name} elb gateway security groups"

  vpc_id = "${aws_vpc.terraformmain.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  #depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_elb" "gateway" {
  name = "${var.cluster-name}-gateway-elb"

  # The same availability zone as our instance
  subnets = ["${aws_subnet.PublicAZA.id}"]

  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 30080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  #listener {
  #  instance_port     = 30443
  #  instance_protocol = "https"
  #  lb_port           = 443
  #  lb_protocol       = "https"
  #}

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:30080"
    interval            = 5
  }

  # The instance is registered automatically

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}