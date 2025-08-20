// Get vpc details of existing horizon-sdv network
data "google_compute_network" "sdv_network_data" {
  name = var.sdv_cloud_ws_network_name
  project = var.sdv_cloud_ws_project_id
}
// Get subnetwork details of existing horizon-sdv subnetwork
data "google_compute_subnetwork" "sdv_cloud_ws_subnetwork_data" {
  name    = var.sdv_cloud_ws_subnetwork_name
  project = var.sdv_cloud_ws_project_id
  region  = var.sdv_cloud_ws_region
}

resource "google_workstations_workstation_cluster" "sdv_cloud_ws_cluster" {
  provider               = google-beta
  project                = var.sdv_cloud_ws_project_id
  workstation_cluster_id = var.sdv_cloud_ws_cluster_name
  network                = data.google_compute_network.sdv_network_data.id
  subnetwork             = data.google_compute_subnetwork.sdv_cloud_ws_subnetwork_data.id
  location               = var.sdv_cloud_ws_region

  # private_cluster_config {
  #   enable_private_endpoint = true
  # }

  # domain_config {
  #   domain = "workstations.example.com"
  # }
}