terraform {
  backend "gcs" {
    bucket = "rss-yoriyori-tfstate"
    prefix = "terraform/state"
  }
}
