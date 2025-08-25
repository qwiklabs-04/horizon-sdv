output "cluster_name" {
  description = "Name of the created Cloud Workstations cluster"
  value       = google_workstations_workstation_cluster.sdv_cloud_ws_cluster.name
}

output "project_id" {
  description = "GCP Project ID where the cluster is deployed"
  value       = var.sdv_cloud_ws_project_id
}

output "location" {
  description = "Region (Location) of the Cloud Workstations cluster"
  value       = google_workstations_workstation_cluster.sdv_cloud_ws_cluster.location
}

output "network_name" {
  description = "GCP network (VPC) name where Cloud Workstations is deployed."
  value       = google_workstations_workstation_cluster.sdv_cloud_ws_cluster.network
}

output "subnetwork_name" {
  description = "GCP subnetwork (VPC subnet) name where Cloud Workstations is deployed."
  value       = google_workstations_workstation_cluster.sdv_cloud_ws_cluster.subnetwork
}
