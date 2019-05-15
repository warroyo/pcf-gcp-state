// Modify dns records to resolve to the ha proxy when in internetless mode.
locals {
  haproxy_static_ip = "${cidrhost(google_compute_subnetwork.pas.ip_cidr_range, -20)}"
  cf_address        = "${var.global_lb ? module.gorouter.global_address : module.gorouter.address}"
  cf_ws_address     = "${var.global_lb ? module.websocket.address : module.gorouter.address}"
}

resource "google_dns_record_set" "wildcard-sys-dns" {
  name = "*.sys.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.cf_address}"]
}

resource "google_dns_record_set" "doppler-sys-dns" {
  name = "doppler.sys.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.cf_ws_address}"]
}

resource "google_dns_record_set" "loggregator-sys-dns" {
  name = "loggregator.sys.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.cf_ws_address}"]
}

resource "google_dns_record_set" "wildcard-apps-dns" {
  name = "*.apps.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.cf_address}"]
}

resource "google_dns_record_set" "wildcard-ws-dns" {
  name = "*.ws.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : local.cf_ws_address}"]
}

resource "google_dns_record_set" "app-ssh-dns" {
  name = "ssh.sys.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : module.ssh-lb.address}"]
}

resource "google_dns_record_set" "tcp-dns" {
  name = "tcp.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300
  count = "${var.create_tcp_router ? 1 : 0}"
  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.internetless ? local.haproxy_static_ip : module.tcprouter.address}"]
}

resource "google_dns_record_set" "wildcard-mesh-dns" {
  name = "*.mesh.apps.${var.dns_zone_dns_name}"
  type = "A"
  ttl  = 300
  count = "${var.create_mesh_lb ? 1 : 0}"
  managed_zone = "${var.dns_zone_name}"

  rrdatas = ["${var.global_lb ? module.mesh.global_address : module.mesh.address}"]
}