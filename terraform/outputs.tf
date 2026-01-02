output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.main.uri
}

output "image_url" {
  description = "Docker image URL (without tag)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/${var.service_name}"
}

output "storage_bucket_name" {
  description = "Cloud Storage bucket name for RSS output"
  value       = google_storage_bucket.rss.name
}

output "storage_bucket_url" {
  description = "Public URL for RSS output"
  value       = "https://storage.googleapis.com/${google_storage_bucket.rss.name}"
}

output "storage_hmac_access_id" {
  description = "HMAC access ID for S3-compatible API"
  value       = google_storage_hmac_key.storage.access_id
}

output "storage_hmac_secret" {
  description = "HMAC secret for S3-compatible API"
  value       = google_storage_hmac_key.storage.secret
  sensitive   = true
}
