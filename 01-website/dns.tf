# ============================================================================================
# FILE: dns.tf
# PURPOSE:
#   - Configure Cloud DNS records for the static website
#   - Point www.<domain> to the global IP of the HTTPS load balancer
# ============================================================================================


# ============================================================================================
# DATA: Existing Cloud DNS Managed Zone
# PURPOSE:
#   - Load the manually created DNS zone (already configured in Google Cloud Console)
#   - Use it to attach DNS record sets in Terraform
# ============================================================================================

data "google_dns_managed_zone" "existing_zone" {
  name = var.zone_name
}

# A record for the www subdomain
resource "google_dns_record_set" "www_record" {
  name         = "www.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# Optional: redirect bare domain (apex) to the same IP
resource "google_dns_record_set" "root_record" {
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}