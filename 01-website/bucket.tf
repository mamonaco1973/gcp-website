# ============================================================================================
# LOCALS: Derive a globally unique GCS bucket name from the domain
# ============================================================================================
locals {
  # Replace dots with hyphens and append short hash for uniqueness
  base_domain   = replace(var.domain_name, ".", "-")
  bucket_suffix = substr(md5(var.domain_name), 0, 6)
  bucket_name   = lower(format("%s-%s", local.base_domain, local.bucket_suffix))
}

# ============================================================================================
# RESOURCE: GCS Bucket for Static Website Hosting
# ============================================================================================
# Creates a Google Cloud Storage bucket configured for static website
# hosting. The name is derived from the domain and made globally unique.
# --------------------------------------------------------------------------------------------
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

# ============================================================================================
# RESOURCE: Upload index.html
# ============================================================================================
# Uploads the local index.html file to the bucket root for site homepage.
# --------------------------------------------------------------------------------------------
resource "google_storage_bucket_object" "index" {
  name         = "index.html"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/index.html"
  content_type = "text/html"
}

# ============================================================================================
# RESOURCE: Upload 404.html
# ============================================================================================
# Uploads the local 404.html file to the bucket root for error handling.
# --------------------------------------------------------------------------------------------
resource "google_storage_bucket_object" "error_page" {
  name         = "404.html"
  bucket       = google_storage_bucket.website.name
  source       = "${path.module}/404.html"
  content_type = "text/html"
}

# ============================================================================================
# RESOURCE: Make Bucket Publicly Readable
# ============================================================================================
# Grants public read access to all objects for static website delivery.
# --------------------------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
