# Cloud Run Domain Mapping
#
# カスタムドメインをCloud Runサービスにマッピング
# 事前にドメインの所有権を確認する必要あり
# https://console.cloud.google.com/run/domains

resource "google_cloud_run_domain_mapping" "custom" {
  location = var.region
  name     = var.custom_domain

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.main.name
  }

  depends_on = [google_cloud_run_v2_service.main]
}

output "domain_mapping_status" {
  value       = google_cloud_run_domain_mapping.custom.status
  description = "Domain mapping status - check for DNS records to configure"
}
