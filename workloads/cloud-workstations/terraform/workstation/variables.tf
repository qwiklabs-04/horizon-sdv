// from jenkins env; same as horizon-sdv value
variable "sdv_cloud_ws_bucket" {
  description = "GCS bucket name where Cloud Workstations tfstate is stored."
  type        = string
  default     = "prj-sbx-horizon-sdv-tf"
}

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

// from jenkins env; new resource
variable "sdv_cloud_ws_cluster_name" {
  description = "Name of the Cloud Workstations cluster."
  type        = string
}

# A map of workstations, keyed by workstation_id:
variable "workstations" {
  type = map(object({
    sdv_cloud_ws_workstation_config_id = string
    sdv_cloud_ws_workstation_id        = string
    sdv_cloud_ws_display_name          = string
    sdv_cloud_ws_user_emails           = list(string)
  }))
  description = "List of Cloud Workstations to manage"

  validation {
    condition = alltrue([
      for ws in values(var.workstations) : (
        # All three required fields must be non-empty
        trim(ws.sdv_cloud_ws_workstation_config_id," ") != "" &&
        trim(ws.sdv_cloud_ws_workstation_id," ") != ""
      )
    ])
    error_message = "WORKSTATION_CONFIG_NAME and WORKSTATION_NAME cannot be empty."
  }

  validation {
    condition = alltrue([
      for ws in values(var.workstations) : (
        # Validate workstation_id: lowercase, hyphens allowed, but cannot start or end with '-'
        can(regex("^([a-z0-9]+(-[a-z0-9]+)*)$", ws.sdv_cloud_ws_workstation_id))
      )
    ])
    error_message = "Each WORKSTATION_NAME must be lowercase, can contain hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for ws in values(var.workstations) : (
        length(distinct(ws.sdv_cloud_ws_user_emails)) == length(ws.sdv_cloud_ws_user_emails)
      )
    ])
    error_message = "Each workstation's INITIAL_WORKSTATION_USER_EMAILS_TO_ADD list cannot contain duplicates."
  }
}

