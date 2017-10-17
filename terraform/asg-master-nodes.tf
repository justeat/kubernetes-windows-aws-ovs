data "template_file" "userdata-master" {
    template = "${file("templates/userdata-master.sh.tpl")}"
    vars {
        bucket_name = "${aws_s3_bucket.bucket.id}"
        public_dns = "${aws_route53_zone.primary.name}"
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
    }
}

resource "aws_autoscaling_group" "master-linux-asg" {
  availability_zones    = ["${var.core-availability-zone}"]
  name                  = "${var.cluster-name}-master-linux"
  max_size              = "1"
  min_size              = "1"
  desired_capacity      = "1"
  force_delete          = true
  vpc_zone_identifier   = ["${aws_subnet.MasterNodes.id}"]
  launch_configuration  = "${aws_launch_configuration.master-linux-lc.name}"
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-master-linux"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "master-linux-lc" {
  name_prefix          = "${var.cluster-name}-master-linux-"
  image_id             = "${lookup(var.AmiLinux, var.region)}"
  instance_type        = "${var.master-linux-instance-type}"
  security_groups      = ["${aws_security_group.Master-Linux.id}"]
  user_data            = "${data.template_file.userdata-master.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.master-nodes-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
}

