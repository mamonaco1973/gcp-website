# ============================================================================================
# FILE: loadbalancer.tf
# PURPOSE:
#   - Create a global HTTPS load balancer fronting the GCS bucket
#   - Enable Cloud CDN for global caching
#   - Attach a Google-managed SSL certificate for HTTPS
# ============================================================================================

# Reserve a global IP address for the website
resource "google_compute_global_address" "website_ip" {
  name = "website-ip"
}

# Backend bucket connected to your GCS bucket
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# URL map that routes all traffic to the backend bucket
resource "google_compute_url_map" "website_map" {
  name            = "website-map"
  default_service = google_compute_backend_bucket.website_backend.id
}

# Google-managed SSL certificate for both apex and www domains
resource "google_compute_managed_ssl_certificate" "website_cert" {
  name = "website-cert"
  managed {
    domains = [
      var.domain_name,
      "www.${var.domain_name}"
    ]
  }
}

# HTTPS proxy using the URL map and SSL cert
resource "google_compute_target_https_proxy" "website_proxy" {
  name             = "website-proxy"
  url_map          = google_compute_url_map.website_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.website_cert.id]
}

# Global forwarding rule for HTTPS traffic (port 443)
resource "google_compute_global_forwarding_rule" "website_https" {
  name                  = "website-https-rule"
  target                = google_compute_target_https_proxy.website_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
}
