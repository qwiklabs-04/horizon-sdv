terraform {
  required_version = ">= 1.9.6"
  backend "gcs" {
    prefix = "horizon-sdv-abfs-uploaders-tf-state"
  }
}
