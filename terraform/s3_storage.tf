resource "aws_s3_bucket" "bucket" {
  bucket = "${var.cluster-name}-k8s-state"
  acl    = "private"
  tags {
    Name        = "${var.cluster-name}-k8s-state"
  }
}

