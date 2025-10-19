# ============================================================================================
# FILE: dns.tf
# PURPOSE:
#   Configure Cloud DNS records for the static website.
#   Point www.<domain> and root domain to the global load balancer IP.
# ============================================================================================

# ============================================================================================
# DATA: Existing Cloud DNS Managed Zone
# ============================================================================================
# Loads the existing DNS zone created manually in Google Cloud Console.
# This allows Terraform to manage DNS records within that zone.
# --------------------------------------------------------------------------------------------
data "google_dns_managed_zone" "existing_zone" {
  name = var.zone_name
}

# ============================================================================================
# RESOURCE: A Record for www Subdomain
# ============================================================================================
# Creates an A record for www.<domain> pointing to the load balancer IP.
# This enables access via the www-prefixed domain.
# --------------------------------------------------------------------------------------------
resource "google_dns_record_set" "www_record" {
  name         = "www.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# ============================================================================================
# RESOURCE: A Record for Root Domain
# ============================================================================================
# Creates an A record for the root domain (apex) pointing to the same IP.
# This allows users to access the site using the bare domain name.
# --------------------------------------------------------------------------------------------
resource "google_dns_record_set" "root_record" {
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}
