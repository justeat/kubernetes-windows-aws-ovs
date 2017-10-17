resource "aws_vpc_dhcp_options" "mydhcp" {
    domain_name = "${var.DnsZoneName}"
    domain_name_servers = ["AmazonProvidedDNS"]
    tags {
      Name = "internal dhcp option"
    }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id = "${aws_vpc.terraformmain.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.mydhcp.id}"
}

