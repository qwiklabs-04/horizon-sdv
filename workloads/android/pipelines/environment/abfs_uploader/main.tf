data "google_project" "project" {
  project_id = var.project_id
}

module "abfs-uploaders" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-abfs.git//modules/uploaders?ref=961f5aa3c3be87a242597cbd4bc08821f28a7085"

  project_id            = var.project_id
  zone                  = var.zone
  service_account_email = "abfs-server@${var.project_id}.iam.gserviceaccount.com"
  subnetwork            = "sdv-subnet"

  abfs_gerrit_uploader_count                     = var.abfs_gerrit_uploader_count
  abfs_gerrit_uploader_machine_type              = var.abfs_gerrit_uploader_machine_type
  abfs_gerrit_uploader_datadisk_size_gb          = var.abfs_gerrit_uploader_datadisk_size_gb
  abfs_gerrit_uploader_datadisk_type             = var.abfs_gerrit_uploader_datadisk_type
  abfs_docker_image_uri                          = var.abfs_docker_image_uri
  abfs_gerrit_uploader_manifest_server           = var.abfs_gerrit_uploader_manifest_server
  abfs_gerrit_uploader_git_branch                = var.abfs_gerrit_uploader_git_branch
  abfs_manifest_project_name                     = var.abfs_manifest_project_name
  abfs_manifest_file                             = var.abfs_manifest_file
  abfs_license                                   = var.abfs_license
  abfs_server_name                               = "abfs-server"
  abfs_gerrit_uploader_allow_stopping_for_update = true
}
