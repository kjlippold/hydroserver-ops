# -------------------------------------------------- #
# Cloud CDN Backend Service                          #
# -------------------------------------------------- #

resource "google_compute_backend_service" "cloud_run_backend" {
  name        = "hydroserver-${var.instance}-cdn-backend"
  description = "Backend service for HydroServer API"
  backend {
    group = google_compute_region_network_endpoint_group.hydroserver_neg.id
  }
  enable_cdn = true
}

# -------------------------------------------------- #
# URL Map                                            #
# -------------------------------------------------- #

resource "google_compute_url_map" "cdn_url_map" {
  name            = "hydroserver-${var.instance}-cdn-url-map"
  default_service = google_compute_backend_service.cloud_run_backend.id
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.cloud_run_backend.self_link
    path_rule {
      paths   = ["/api/*", "/admin/*"]
      service = google_compute_backend_service.cloud_run_backend.self_link
    }
  }
}

# -------------------------------------------------- #
# HTTP(S) Proxy                                      #
# -------------------------------------------------- #

resource "google_compute_target_http_proxy" "cdn_http_proxy" {
  name    = "hydroserver-${var.instance}-cdn-http-proxy"
  url_map = google_compute_url_map.cdn_url_map.id
}

# -------------------------------------------------- #
# Global Static IP Address                           #
# -------------------------------------------------- #

resource "google_compute_global_address" "cdn_ip_address" {
  name = "hydroserver-${var.instance}-cdn-ip"
}

# -------------------------------------------------- #
# Global Forwarding Rule                             #
# -------------------------------------------------- #

resource "google_compute_global_forwarding_rule" "cdn_forwarding_rule" {
  name       = "hydroserver-${var.instance}-cdn-forwarding"
  ip_address = google_compute_global_address.cdn_ip_address.id
  target     = google_compute_target_http_proxy.cdn_http_proxy.id
  port_range = "80"
  load_balancing_scheme = "EXTERNAL"
}
