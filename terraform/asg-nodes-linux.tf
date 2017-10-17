data "template_file" "userdata-linux-node" {
    template = "${file("templates/userdata-nodes.sh.tpl")}"
    vars {
        bucket_name = "${aws_s3_bucket.bucket.id}"
        k8s_version = "${var.k8s_version}"
        k8s_pod_subnet = "${var.k8s_pod_subnet}"
        k8s_node_pod_subnet = "${var.k8s_node_pod_subnet}"
        k8s_service_subnet =  "${var.k8s_service_subnet}"
        k8s_api_service_ip =  "${var.k8s_api_service_ip}"
        k8s_dns_version = "${var.k8s_dns_version}"
        k8s_dns_service_ip = "${var.k8s_dns_service_ip}"
        k8s_dns_domain = "${var.k8s_dns_domain}"
        etcd_version =  "${var.etcd_version}"
        master_internal_ip = "${var.master_internal_ip}"
        k8s_pod_subnet_prefix = "${var.k8s_pod_subnet_prefix}"
    }
}

resource "aws_autoscaling_group" "node-linux-asg" {
  availability_zones   = ["${var.core-availability-zone}"]
  name                 = "${var.cluster-name}-node-linux"
  max_size             = "${var.node-linux-asg-max-size}"
  min_size             = "${var.node-linux-asg-min-size}"
  desired_capacity     = "${var.node-linux-asg-desired-capacity}"
  force_delete         = true
  vpc_zone_identifier  = ["${aws_subnet.Nodes.id}"]
  launch_configuration = "${aws_launch_configuration.node-linux-lc.name}"
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-node-linux"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "node-linux-lc" {
  name_prefix          = "${var.cluster-name}-node-linux-"
  image_id             = "${lookup(var.AmiLinux, var.region)}"
  instance_type        = "${var.node-linux-instance-type}"
  security_groups      = ["${aws_security_group.Node.id}"]
  user_data            = "${data.template_file.userdata-linux-node.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.nodes-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type = "${var.node-linux-lc-volume-type}"
    volume_size = "${var.node-linux-lc-volume-size}"
    delete_on_termination = "true"
  }
}

