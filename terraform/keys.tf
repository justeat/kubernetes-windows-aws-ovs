resource "aws_key_pair" "keypair" {
  key_name   = "${var.cluster-name}"
  public_key = "<insert keypair here>"
}