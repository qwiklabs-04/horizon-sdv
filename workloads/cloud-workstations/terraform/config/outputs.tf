locals {
  config                = try(google_workstations_workstation_config.sdv_cloud_ws_config[var.sdv_cloud_ws_input_config_name], null)
  deleted_config_output = "[DELETED CONFIG] ${var.sdv_cloud_ws_input_config_name}"
}

output "config_name" {
  description = "Name of the Cloud WS Config resource."
  value       = try(local.config.workstation_config_id, local.deleted_config_output)
}

output "config_machine_type" {
  description = "Name of the machine type used by the Cloud WS Config."
  value       = try(local.config.host[0].gce_instance[0].machine_type, local.deleted_config_output)
}

output "config_container_image" {
  description = "Name of the container image used by the Cloud WS Config."
  value       = try(local.config.container[0].image, local.deleted_config_output)
}

output "workstation_auto_sleep_in_seconds" {
  value = try(local.config.idle_timeout, local.deleted_config_output)
}

output "workstation_quickstart_pool_size" {
  value = try(local.config.host[0].gce_instance[0].pool_size, local.deleted_config_output)
}

// -----Preset properties outputs------
output "cluster_name" {
  description = "Name of the Cloud WS cluster that contains configs and workstations."
  value       = var.sdv_cloud_ws_cluster_name
}

output "project_id" {
  description = "GCP Project ID where the Cloud WS cluster, configs and workstations are deployed."
  value       = var.sdv_cloud_ws_project_id
}

output "location" {
  description = "Region (Location) where Cloud WS cluster, configs and workstations are deployed."
  value       = var.sdv_cloud_ws_region
}
