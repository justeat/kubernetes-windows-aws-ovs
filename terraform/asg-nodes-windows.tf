data "template_file" "userdata-windows-node" {
    template = "${file("templates/userdata-nodes.ps1.tpl")}"
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
        k8s_pod_subnet_network = "${var.k8s_pod_subnet_network}"
    }
}

resource "aws_autoscaling_group" "node-windows-asg" {
  availability_zones   = ["${var.core-availability-zone}"]
  name                 = "${var.cluster-name}-node-windows"
  max_size             = "${var.node-windows-asg-max-size}"
  min_size             = "${var.node-windows-asg-min-size}"
  desired_capacity     = "${var.node-windows-asg-desired-capacity}"
  force_delete         = true
  vpc_zone_identifier  = ["${aws_subnet.Nodes.id}"]
  launch_configuration = "${aws_launch_configuration.node-windows-lc.name}"
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-node-windows"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "node-windows-lc" {
  name_prefix          = "${var.cluster-name}-node-windows-"
  image_id             = "${lookup(var.AmiWindows, var.region)}"
  instance_type        = "${var.node-windows-instance-type}"
  security_groups      = ["${aws_security_group.Node.id}"]
  user_data            = "${data.template_file.userdata-windows-node.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.nodes-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type = "${var.node-windows-lc-volume-type}"
    volume_size = "${var.node-windows-lc-volume-size}"
    delete_on_termination = "true"
  }
}

data "template_file" "install-k8s-ps1" {
    template = "${file("templates/install_k8s.ps1.tpl")}"
    vars {
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
        k8s_pod_subnet_network = "${var.k8s_pod_subnet_network}"
    }
}

resource "aws_s3_bucket_object" "install_ovn" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/install_ovn.ps1"
  source = "files/install_ovn.ps1"
  etag   = "${md5(file("files/install_ovn.ps1"))}"
}

resource "aws_s3_bucket_object" "install-k8s" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/install_k8s.ps1"
  source = "files/install_k8s.ps1"
  etag   = "${md5(file("files/install_k8s.ps1"))}"
}

resource "aws_s3_bucket_object" "startup" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/startup.ps1"
  source = "files/startup.ps1"
  etag   = "${md5(file("files/startup.ps1"))}"
}

resource "aws_s3_bucket_object" "ovn-controller" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "bin/ovn-controller.exe"
  source = "bin/ovn-controller.exe"
  etag   = "${md5(file("bin/ovn-controller.exe"))}"
}

resource "aws_s3_bucket_object" "k8s-ovn-exe" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "bin/k8s_ovn.exe"
  source = "bin/k8s_ovn.exe"
  etag   = "${md5(file("bin/k8s_ovn.exe"))}"
}