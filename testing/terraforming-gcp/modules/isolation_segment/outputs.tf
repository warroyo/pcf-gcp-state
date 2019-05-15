output "load_balancer_name" {
  value = "${module.isoseg.name}"
}

output "domain" {
  value = "${replace(replace(element(concat(google_dns_record_set.wildcard-iso-dns.*.name, list("")), 0), "/^\\*\\./", ""), "/\\.$/", "")}"
}

output "haproxy_static_ip" {
  value = "${local.haproxy_static_ip}"
}
