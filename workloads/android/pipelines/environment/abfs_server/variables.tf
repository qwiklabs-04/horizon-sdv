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

variable "abfs_server_machine_type" {
  type        = string
  description = "Machine type for ABFS gerrit server"
}

variable "abfs_server_datadisk_size_gb" {
  type        = number
  description = "Size in GB for the ABFS server datadisk"
}

variable "abfs_license" {
  type        = string
  description = "ABFS license (JSON)"
}
