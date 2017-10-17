resource "aws_subnet" "PublicAZA" {
  vpc_id = "${aws_vpc.terraformmain.id}"
  cidr_block = "${var.Subnet-Public-AzA-CIDR}"
  tags {
        Name = "${var.cluster-name}-Public"
  }
 availability_zone = "${var.core-availability-zone}"
}
resource "aws_route_table_association" "PublicAZA" {
    subnet_id = "${aws_subnet.PublicAZA.id}"
    route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "Nodes" {
  vpc_id = "${aws_vpc.terraformmain.id}"
  cidr_block = "${var.Subnet-Nodes-CIDR}"
  tags {
        Name = "${var.cluster-name}-Nodes"
  }
  availability_zone = "${var.core-availability-zone}"
}
resource "aws_route_table_association" "Nodes" {
    subnet_id = "${aws_subnet.Nodes.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_subnet" "MasterNodes" {
  vpc_id = "${aws_vpc.terraformmain.id}"
  cidr_block = "${var.Subnet-Master-CIDR}"
  tags {
        Name = "${var.cluster-name}-MasterNodes"
  }
  availability_zone = "${var.core-availability-zone}"
}
resource "aws_route_table_association" "MasterNodes" {
    subnet_id = "${aws_subnet.MasterNodes.id}"
    route_table_id = "${aws_route_table.private.id}"
}



