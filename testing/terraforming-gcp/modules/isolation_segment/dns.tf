locals {
  haproxy_static_ip = "${cidrhost(var.pas_subnet_cidr, -19)}"
  isoseg_address        = "${var.global_lb ? module.isoseg.global_address : module.isoseg.address}"
}

resource "google_dns_record_set" "wildcard-iso-dns" {
  name  = "*.iso.${var.dns_zone_dns_name}."
  type  = "A"
  ttl   = 300
  count = "${var.count}"

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.isoseg_address}"]
}
