resource "aws_security_group" "elb-api" {
  name        = "${var.cluster-name}-elb-api-gateway"
  description = "${var.cluster-name} elb api gateway security groups"

  vpc_id = "${aws_vpc.terraformmain.id}"

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

resource "aws_elb" "api-gateway" {
  name = "${var.cluster-name}-gateway-elb-api"

  # The same availability zone as our instance
  subnets = ["${aws_subnet.PublicAZA.id}"]

  security_groups = ["${aws_security_group.elb-api.id}"]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:443"
    interval            = 5
  }

  # The instance is registered automatically

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_autoscaling_attachment" "elb-asg-api" {
  elb                    = "${aws_elb.api-gateway.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-linux-asg.id}"
}