variable "TAG" {
  default = "latest"
}

variable "REGISTRY" {
  default = "asia-northeast1-docker.pkg.dev/rss-yoriyori/rss-yoriyori"
}

group "default" {
  targets = ["rss-yoriyori"]
}

target "rss-yoriyori" {
  dockerfile = "Dockerfile"
  context    = "."
  platforms  = ["linux/amd64"]
  tags = [
    "${REGISTRY}/rss-yoriyori:${TAG}",
    "${REGISTRY}/rss-yoriyori:latest"
  ]
  push = true
}
