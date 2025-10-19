# ============================================================================================
# LOCALS: Derive a globally unique GCS bucket name from the domain
# ============================================================================================
locals {
  # Remove dots from domain and append a short hash/suffix for uniqueness
  base_domain   = replace(var.domain_name, ".", "-")
  bucket_suffix = substr(md5(var.domain_name), 0, 6)
  bucket_name   = lower(format("%s-%s", local.base_domain, local.bucket_suffix))
}

resource "google_storage_bucket" "website" {
  name          = local.bucket_name
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  uniform_bucket_level_access = true
}
