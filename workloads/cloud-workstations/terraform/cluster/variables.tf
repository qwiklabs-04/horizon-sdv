// from jenkins env; same as horizon-sdv value
variable "sdv_cloud_ws_project_id" {
  description = "GCP Project ID (existing) where Cloud Workstations is deployed."
  type        = string
}

// from jenkins env; same as horizon-sdv value
variable "sdv_cloud_ws_region" {
  description = "GCP region where Cloud Workstations is deployed."
  type        = string
}

// from jenkins env; same as horizon-sdv value
variable "sdv_cloud_ws_network_name" {
  description = "GCP network (VPC) name where Cloud Workstations is deployed."
  type        = string
}

// from jenkins env; same as horizon-sdv value
variable "sdv_cloud_ws_subnetwork_name" {
  description = "GCP subnetwork (VPC subnet) name where Cloud Workstations is deployed."
  type        = string
}

// from jenkins env; new resource
variable "sdv_cloud_ws_cluster_name" {
  description = "Name of the Cloud Workstations cluster."
  type        = string
}