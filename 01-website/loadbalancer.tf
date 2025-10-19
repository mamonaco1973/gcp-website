# ============================================================================================
# FILE: loadbalancer.tf
# PURPOSE:
#   Create a global HTTPS load balancer for the static website.
#   Fronts the GCS bucket, enables Cloud CDN, and applies HTTPS certs.
# ============================================================================================

# ============================================================================================
# RESOURCE: Global IP Address
# ============================================================================================
# Reserves a static, global IP address used by the HTTPS load balancer.
# --------------------------------------------------------------------------------------------
resource "google_compute_global_address" "website_ip" {
  name = "website-ip"
}

# ============================================================================================
# RESOURCE: Backend Bucket
# ============================================================================================
# Connects the GCS bucket to the load balancer as a backend.
# Enables Cloud CDN for global caching and low latency delivery.
# --------------------------------------------------------------------------------------------
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# ============================================================================================
# RESOURCE: URL Map
# ============================================================================================
# Routes all incoming HTTP(S) requests to the backend bucket.
# Acts as the central routing configuration for the load balancer.
# --------------------------------------------------------------------------------------------
resource "google_compute_url_map" "website_map" {
  name            = "website-map"
  default_service = google_compute_backend_bucket.website_backend.id
}

# ============================================================================================
# RESOURCE: Managed SSL Certificate
# ============================================================================================
# Provisions a Google-managed SSL certificate for both apex and www domains.
# Certificate status may take time to become ACTIVE after creation.
# --------------------------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "website_cert" {
  name = "website-cert"
  managed {
    domains = [
      var.domain_name,
      "www.${var.domain_name}"
    ]
  }
}

# ============================================================================================
# RESOURCE: HTTPS Proxy
# ============================================================================================
# Defines the HTTPS target proxy that binds the SSL cert and URL map.
# All secure traffic flows through this proxy to the backend.
# --------------------------------------------------------------------------------------------
resource "google_compute_target_https_proxy" "website_proxy" {
  name             = "website-proxy"
  url_map          = google_compute_url_map.website_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.website_cert.id]
}

# ============================================================================================
# RESOURCE: Global Forwarding Rule
# ============================================================================================
# Creates the entry point for HTTPS traffic on port 443.
# Directs requests to the HTTPS proxy using the reserved global IP.
# --------------------------------------------------------------------------------------------
resource "google_compute_global_forwarding_rule" "website_https" {
  name                  = "website-https-rule"
  target                = google_compute_target_https_proxy.website_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
}
