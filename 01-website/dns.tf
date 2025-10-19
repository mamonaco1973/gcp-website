# ============================================================================================
# FILE: dns.tf
# PURPOSE:
#   - Configure Cloud DNS records for the static website
#   - Point www.<domain> to the global IP of the HTTPS load balancer
# ============================================================================================

# Reference existing managed DNS zone (created manually or via Terraform)
resource "google_dns_managed_zone" "website_zone" {
  name        = "website-zone"
  dns_name    = "${var.domain_name}."
  description = "Managed zone for ${var.domain_name}"
}

# A record for the www subdomain
resource "google_dns_record_set" "www_record" {
  name         = "www.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.website_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# Optional: redirect bare domain (apex) to the same IP
resource "google_dns_record_set" "root_record" {
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.website_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}