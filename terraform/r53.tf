resource "aws_route53_zone" "primary" {
  name = "${var.cluster-name}.${var.dns-zone}"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "api.${var.cluster-name}.${var.dns-zone}"
  type    = "A"

  alias {
    name                   = "${aws_elb.api-gateway.dns_name}"
    zone_id                = "${aws_elb.api-gateway.zone_id}"
    evaluate_target_health = true
  }
}

