# ============================================================================================
# FRONT DOOR PROFILE
# ============================================================================================
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "mcs-fd-profile"
  resource_group_name = azurerm_resource_group.website_rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

# ============================================================================================
# FRONT DOOR ENDPOINT
# ============================================================================================
resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "mcs-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

# ============================================================================================
# FRONT DOOR ORIGIN GROUP AND ORIGIN (Storage Account)
# ============================================================================================
# Defines the origin group and origin used by Azure Front Door.
# The origin group requires load_balancing and health_probe blocks.
# --------------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "fd_group" {
  name                     = "mcs-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  session_affinity_enabled = false

  # ------------------------------------------------------------------------------------------
  # Load balancing configuration (basic single-origin setup)
  # ------------------------------------------------------------------------------------------
  load_balancing {
    sample_size                 = 4
    successful_samples_required = 2
  }

  # ------------------------------------------------------------------------------------------
  # Health probe configuration (Front Door checks origin health)
  # ------------------------------------------------------------------------------------------
  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

# ============================================================================================
# FRONT DOOR ORIGIN (Storage Account)
# ============================================================================================
# Defines the backend origin for the Front Door endpoint.
# Removes both "https://" and any trailing slash from the static website URL.
# --------------------------------------------------------------------------------------------
locals {
  # Remove "https://" first, then trim trailing "/"
  storage_origin_host = replace(
    replace(azurerm_storage_account.sa.primary_web_endpoint, "https://", ""),
    "/",
    ""
  )
}

# ============================================================================================
# FRONT DOOR ORIGIN (Storage Account)
# ============================================================================================
# Defines the backend origin for the Front Door endpoint.
# The origin uses the Azure Storage static website endpoint.
# --------------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin" "fd_origin" {
  name                          = "mcs-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_group.id
  enabled                       = true
  host_name                     = local.storage_origin_host
  origin_host_header            = local.storage_origin_host
  http_port                     = 80
  https_port                    = 443
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# ============================================================================================
# FRONT DOOR ROUTE - MAP TRAFFIC TO STORAGE + BIND CUSTOM DOMAINS
# ============================================================================================
resource "azurerm_cdn_frontdoor_route" "fd_route" {
  name                          = "mcs-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_group.id

  # At least one origin ID is required (not just the group)
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.fd_origin.id
  ]

  # Match all paths and force HTTPS
  patterns_to_match             = ["/*"]
  https_redirect_enabled        = true
  supported_protocols           = ["Http", "Https"]
  link_to_default_domain        = false   # Disable *.azurefd.net
  enabled                       = true

  # ------------------------------------------------------------------------------------------
  # Bind the custom domains (root + www) to this route
  # ------------------------------------------------------------------------------------------
  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_root.id,
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_www.id
  ]

  depends_on = [
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_root,
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_www
  ]

}

# ================================================================================================
# FRONT DOOR CUSTOM DOMAIN - ROOT (mikes-cloud-solutions.org)
# ================================================================================================
resource "azurerm_cdn_frontdoor_custom_domain" "fd_custom_domain_root" {
  name                     = "mcs-root-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  host_name                = var.domain_name
  dns_zone_id              = data.azurerm_dns_zone.existing_zone.id

  # ----------------------------------------------------------------------------------------------
  # TLS block is now required in the azurerm_cdn_frontdoor_custom_domain resource.
  # "certificate_type = ManagedCertificate" tells Azure to issue and bind a cert automatically.
  # ----------------------------------------------------------------------------------------------
  tls {
    certificate_type    = "ManagedCertificate"
  }
}

# ================================================================================================
# FRONT DOOR CUSTOM DOMAIN - WWW (www.mikes-cloud-solutions.org)
# ================================================================================================
resource "azurerm_cdn_frontdoor_custom_domain" "fd_custom_domain_www" {
  name                     = "mcs-www-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  host_name                = "www.${var.domain_name}"
  dns_zone_id              = data.azurerm_dns_zone.existing_zone.id

  tls {
    certificate_type = "ManagedCertificate"
  }
}

# ================================================================================================
# DATA SOURCE - FETCH VALIDATION TOKEN FOR FRONT DOOR CUSTOM DOMAIN (WWW)
# ================================================================================================
# The Azurerm provider doesn't currently expose validation_properties,
# so we use the AzAPI provider to query the raw ARM resource directly.
# -----------------------------------------------------------------------------------------------
data "azapi_resource" "fd_custom_domain_www_raw" {
  type      = "Microsoft.Cdn/profiles/customDomains@2023-05-01"
  parent_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  name      = azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_www.name
}

# ================================================================================================
# DNS TXT RECORD - AUTOMATIC FRONT DOOR VALIDATION (WWW)
# ================================================================================================
# Uses the validation token extracted via AzAPI from the raw ARM object.
# -----------------------------------------------------------------------------------------------
resource "azurerm_dns_txt_record" "afd_validation_www" {
  name                = "_dnsauth.www"
  zone_name           = data.azurerm_dns_zone.existing_zone.name
  resource_group_name = data.azurerm_dns_zone.existing_zone.resource_group_name
  ttl                 = 300

  record {
    value = data.azapi_resource.fd_custom_domain_www_raw.output.properties.validationProperties.validationToken
  }

  depends_on = [
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_www
  ]
}

# ================================================================================================
# DATA SOURCE - FETCH VALIDATION TOKEN FOR FRONT DOOR CUSTOM DOMAIN (ROOT)
# ================================================================================================
data "azapi_resource" "fd_custom_domain_root_raw" {
  type      = "Microsoft.Cdn/profiles/customDomains@2023-05-01"
  parent_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  name      = azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_root.name
}

# ================================================================================================
# DNS TXT RECORD - AUTOMATIC FRONT DOOR VALIDATION (ROOT)
# ================================================================================================
# Azure Front Door requires a TXT record (_dnsauth) to prove ownership of the root domain
# before it can issue the Managed Certificate for HTTPS.
# -----------------------------------------------------------------------------------------------
resource "azurerm_dns_txt_record" "afd_validation_root" {
  name                = "_dnsauth" # No ".www" since it's for the apex/root
  zone_name           = data.azurerm_dns_zone.existing_zone.name
  resource_group_name = data.azurerm_dns_zone.existing_zone.resource_group_name
  ttl                 = 300

  record {
    value = data.azapi_resource.fd_custom_domain_root_raw.output.properties.validationProperties.validationToken
  }

  depends_on = [
    azurerm_cdn_frontdoor_custom_domain.fd_custom_domain_root
  ]
}

