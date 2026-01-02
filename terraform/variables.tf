variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "rss-yoriyori"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "scheduler_cron" {
  description = "Cron schedule for feed aggregation (Cloud Scheduler)"
  type        = string
  default     = "0 * * * *" # 毎時0分
}

variable "github_repo" {
  description = "GitHub repository (owner/repo)"
  type        = string
  default     = "lacolaco/rss-yoriyori"
}
