data "template_file" "userdata-gateway" {
    template = "${file("templates/userdata-gateway.sh.tpl")}"
    vars {
        bucket_name = "${aws_s3_bucket.bucket.id}"
        k8s_version = "${var.k8s_version}"
        k8s_pod_subnet = "${var.k8s_pod_subnet}"
        k8s_node_pod_subnet = "${var.k8s_node_pod_subnet}"
    }
}

resource "aws_autoscaling_group" "gateway-asg" {
  availability_zones   = ["${var.core-availability-zone}"]
  name                 = "${var.cluster-name}-gateway"
  max_size             = "1"
  min_size             = "1"
  desired_capacity     = "1"
  force_delete         = true
  vpc_zone_identifier  = ["${aws_subnet.Nodes.id}"]
  launch_configuration = "${aws_launch_configuration.gateway-lc.name}"
  load_balancers       = ["${aws_elb.gateway.name}"]
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-gateway"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "gateway-lc" {
  name_prefix          = "${var.cluster-name}-gateway-"
  image_id             = "${lookup(var.AmiLinux, var.region)}"
  instance_type        = "${var.gateway-linux-instance-type}"
  security_groups      = ["${aws_security_group.Gateway.id}"]
  user_data            = "${data.template_file.userdata-gateway.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.gateway-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
}