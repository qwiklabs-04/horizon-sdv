locals {
  deleted_cluster_output = "[DELETED CLUSTER] ${var.sdv_cloud_ws_cluster_name}"
}

output "cluster_name" {
  description = "Name of the created Cloud Workstations cluster"
  value       = try(google_workstations_workstation_cluster.sdv_cloud_ws_cluster.name, local.deleted_cluster_output)
}

output "project_id" {
  description = "GCP Project ID where the cluster is deployed"
  value       = var.sdv_cloud_ws_project_id
}

output "location" {
  description = "Region (Location) of the Cloud Workstations cluster"
  value       = var.sdv_cloud_ws_region
}

output "network_name" {
  description = "GCP network (VPC) name where Cloud Workstations is deployed."
  value       = var.sdv_cloud_ws_network_name
}

output "subnetwork_name" {
  description = "GCP subnetwork (VPC subnet) name where Cloud Workstations is deployed."
  value       = var.sdv_cloud_ws_subnetwork_name
}
