terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 必要なAPIを有効化
resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler" {
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry - Dockerイメージ保存用
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = var.service_name
  format        = "DOCKER"
  description   = "Docker repository for ${var.service_name}"

  depends_on = [google_project_service.artifactregistry]
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    service_account = google_service_account.storage.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.service_name}/${var.service_name}:${var.image_tag}"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      # S3互換ストレージ設定
      env {
        name  = "S3_ENDPOINT"
        value = "storage.googleapis.com"
      }
      env {
        name  = "S3_BUCKET"
        value = google_storage_bucket.rss.name
      }
      env {
        name  = "S3_USE_SSL"
        value = "true"
      }
      # 注意: HMAC キーは terraform output で取得し、Secret Manager経由で設定することを推奨
      # 現在は直接設定（本番運用では Secret Manager を使用すること）
      env {
        name  = "S3_ACCESS_KEY"
        value = google_storage_hmac_key.storage.access_id
      }
      env {
        name  = "S3_SECRET_KEY"
        value = google_storage_hmac_key.storage.secret
      }

      # ヘルスチェック
      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 0
        period_seconds        = 10
        failure_threshold     = 3
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [google_project_service.run]
}

# 公開アクセス許可（認証不要）
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.main.name
  location = google_cloud_run_v2_service.main.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ----------------------------------------------------------------------------
# Cloud Storage（S3互換API経由でアクセス）
# ----------------------------------------------------------------------------

# Storage API を有効化
resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# RSS出力用バケット
resource "google_storage_bucket" "rss" {
  name          = "${var.project_id}-${var.service_name}-rss"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  # CORS設定（RSSリーダーからのアクセス許可）
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  depends_on = [google_project_service.storage]
}

# S3互換API用サービスアカウント
resource "google_service_account" "storage" {
  account_id   = "${var.service_name}-storage"
  display_name = "Storage access for ${var.service_name}"
}

# サービスアカウントにStorage Object Adminロールを付与
resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.rss.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.storage.email}"
}

# HMAC キー（S3互換APIアクセス用）
resource "google_storage_hmac_key" "storage" {
  service_account_email = google_service_account.storage.email
}

# ----------------------------------------------------------------------------
# Cloud Scheduler（定期実行）
# ----------------------------------------------------------------------------

# Scheduler用サービスアカウント
resource "google_service_account" "scheduler" {
  account_id   = "${var.service_name}-scheduler"
  display_name = "Scheduler for ${var.service_name}"
}

# SchedulerにCloud Run起動権限を付与
resource "google_cloud_run_v2_service_iam_member" "scheduler_invoker" {
  name     = google_cloud_run_v2_service.main.name
  location = google_cloud_run_v2_service.main.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

# Cloud Schedulerジョブ
resource "google_cloud_scheduler_job" "aggregate" {
  name        = "${var.service_name}-aggregate"
  description = "Trigger feed aggregation"
  schedule    = var.scheduler_cron
  time_zone   = "Asia/Tokyo"
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.main.uri}/aggregate"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  retry_config {
    retry_count = 3
  }

  depends_on = [google_project_service.cloudscheduler]
}
