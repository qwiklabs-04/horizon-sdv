// Map each workstation key to its list of user emails
locals {
  emails_by_cloud_ws = {
    for ws_id, ws in var.workstations :
    ws_id => ws.sdv_cloud_ws_user_emails
  }
}

// Create the workstation instance
resource "google_workstations_workstation" "sdv_cloud_ws" {
  for_each = var.workstations

  provider                = google-beta
  project                 = var.sdv_cloud_ws_project_id
  location                = var.sdv_cloud_ws_region
  workstation_cluster_id  = var.sdv_cloud_ws_cluster_name
  workstation_config_id   = each.value.sdv_cloud_ws_workstation_config_id
  workstation_id          = each.value.sdv_cloud_ws_workstation_id
  display_name            = each.value.sdv_cloud_ws_display_name
}

// Grant users the Workstation User role (this gives workstations.workstations.use permission)
resource "google_workstations_workstation_iam_binding" "sdv_cloud_ws_user_bindings" {
  for_each = local.emails_by_cloud_ws

  provider               = google-beta
  project                = var.sdv_cloud_ws_project_id
  location               = var.sdv_cloud_ws_region
  workstation_cluster_id = var.sdv_cloud_ws_cluster_name
  workstation_config_id  = var.workstations[each.key].sdv_cloud_ws_workstation_config_id
  workstation_id         = var.workstations[each.key].sdv_cloud_ws_workstation_id

  role    = "roles/workstations.user"
  members = [
    for email in each.value :
    "user:${email}"
  ]
}