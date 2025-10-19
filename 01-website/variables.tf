# ============================================================================================
# FILE: variables.tf
# PURPOSE:
#   - Define input variables required for the Terraform configuration
#   - Centralize domain configuration for Google Cloud DNS and related resources
# ============================================================================================

# ============================================================================================
# VARIABLE: Domain Name
# ============================================================================================
# Defines the fully qualified domain name (FQDN) of the Google Cloud DNS managed zone.
# This value is used across multiple resources (e.g., DNS records, SSL certificates)
# to maintain consistent naming and DNS resolution.
#
# Example:
#   mikes-cloud-solutions.net
#
# NOTE:
#   - Do NOT include a trailing dot (.) as Cloud DNS managed zones are stored without it.
#   - Replace the default value with your actual registered domain name.
# --------------------------------------------------------------------------------------------
variable "domain_name" {
  description = "Fully qualified domain name of the GCP Cloud DNS managed zone (e.g., mikes-cloud-solutions.net)"
  type        = string
  default     = "mikes-cloud-solutions.net"  # Replace with your domain
}

variable "zone_name" {
  description = "Zone name in Cloud DNS corresponding to the domain (e.g., mikes-cloud-solutions-net)"
  type        = string
  default     = "mikes-cloud-solutions-net"  # Replace with your domain
}

