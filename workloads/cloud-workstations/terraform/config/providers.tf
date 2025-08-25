provider "google" {
  project = var.sdv_cloud_ws_project_id
  region  = var.sdv_cloud_ws_region
}

provider "google-beta" {
  project = var.sdv_cloud_ws_project_id
  region  = var.sdv_cloud_ws_region
}