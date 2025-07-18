data "google_project" "project" {
  project_id = var.project_id
}

module "abfs-server" {
  source                                = "git::https://github.com/terraform-google-modules/terraform-google-abfs.git//modules/server?ref=961f5aa3c3be87a242597cbd4bc08821f28a7085"
  project_id                            = var.project_id
  zone                                  = var.zone
  service_account_email                 = "abfs-server@${var.project_id}.iam.gserviceaccount.com"
  subnetwork                            = "sdv-subnet"
  abfs_bucket_location                  = var.region
  abfs_spanner_instance_config          = "regional-${var.region}"
  abfs_docker_image_uri                 = var.abfs_docker_image_uri
  abfs_license                          = var.abfs_license
  abfs_server_machine_type              = var.abfs_server_machine_type
  abfs_server_name                      = "abfs-server"
  abfs_server_allow_stopping_for_update = true
}

resource "google_compute_firewall" "abfs-server-allow-all-from-internal" {
  name    = "abfs-server-allow-all-from-internal"
  network = var.sdv_network

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]

  target_service_accounts = ["abfs-server@${var.project_id}.iam.gserviceaccount.com"]
}
