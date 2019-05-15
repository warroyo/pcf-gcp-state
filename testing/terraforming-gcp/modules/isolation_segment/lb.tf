module "isoseg" {
  source = "../load_balancer"

  env_name = "${var.env_name}"
  name     = "${var.env_name}-isoseg"

  global                     = "${var.global_lb}"
  url_map_name               = "${var.env_name}-isoseg"
  http_proxy_name            = "${var.env_name}-isoseg-http-proxy"
  https_proxy_name           = "${var.env_name}-isoseg-https-proxy"
  http_forwarding_rule_name  = "${var.env_name}-isoseg-lb-http"
  https_forwarding_rule_name = "${var.env_name}-isoseg-lb-https"

  count           = "${var.count}"
  network         = "${var.network}"
  zones           = "${var.zones}"
  ssl_certificate = "${var.ssl_certificate}"

  ports = ["80", "443"]

  optional_target_tag   = ""
  lb_name               = "${var.env_name}-isoseg"
  forwarding_rule_ports = ["80", "443"]

  health_check                     = true
  health_check_port                = "8080"
  health_check_endpoint            = "/health"
  health_check_interval            = 5
  health_check_timeout             = 3
  health_check_healthy_threshold   = 6
  health_check_unhealthy_threshold = 3

}