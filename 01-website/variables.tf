# ============================================================================================
# FILE: variables.tf
# PURPOSE:
#   Define input variables for the Terraform configuration.
#   Centralize domain settings for Cloud DNS and related resources.
# ============================================================================================

# ============================================================================================
# VARIABLE: Domain Name
# ============================================================================================
# Specifies the fully qualified domain name (FQDN) of the Cloud DNS zone.
# Used by multiple resources such as DNS records and SSL certificates.
# --------------------------------------------------------------------------------------------
# Example:
#   mikes-cloud-solutions.net
#
# Notes:
#   - Do not include a trailing dot (.).
#   - Replace the default value with your registered domain name.
# --------------------------------------------------------------------------------------------
variable "domain_name" {
  description = "FQDN of the Cloud DNS managed zone (e.g., mikes-cloud-solutions.net)"
  type        = string
  default     = "mikes-cloud-solutions.net"  # Replace with your domain
}

# ============================================================================================
# VARIABLE: Zone Name
# ============================================================================================
# Defines the name of the existing Cloud DNS managed zone in Google Cloud.
# Used to reference the correct DNS zone when creating record sets.
# --------------------------------------------------------------------------------------------
# Example:
#   mikes-cloud-solutions-net
# --------------------------------------------------------------------------------------------
variable "zone_name" {
  description = "Cloud DNS managed zone name (e.g., mikes-cloud-solutions-net)"
  type        = string
  default     = "mikes-cloud-solutions-net"  # Replace with your zone name
}
