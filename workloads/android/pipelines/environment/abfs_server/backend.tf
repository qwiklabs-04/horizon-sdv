terraform {
  required_version = ">= 1.9.6"
  backend "gcs" {
    bucket = "prj-sbx-horizon-sdv-tf"
    prefix = "horizon-sdv-abfs-server-tf-state"
  }
}
