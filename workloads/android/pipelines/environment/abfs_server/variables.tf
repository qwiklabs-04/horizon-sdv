variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for ABFS servers"
}

variable "zone" {
  type        = string
  description = "Zone for ABFS servers"
}

variable "sdv_network" {
  description = "Name of the network"
  type        = string
}

variable "abfs_server_machine_type" {
  type        = string
  description = "Machine type for ABFS gerrit server"
}

variable "abfs_docker_image_uri" {
  type        = string
  description = "Docker image URI for main ABFS server"
}

variable "abfs_license" {
  type        = string
  description = "ABFS license (JSON)"
}

variable "abfs_server_allow_stopping_for_update" {
  type        = bool
  description = "Allow to stop the server to update properties"
  default     = true
}
