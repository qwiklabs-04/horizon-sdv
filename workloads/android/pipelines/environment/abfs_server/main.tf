data "google_project" "project" {
  project_id = var.project_id
}

module "abfs-server" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-abfs.git//modules/server?ref=d28162880322f56eb49445ce89b0a9d1073a4677"

  project_id               = var.project_id
  zone                     = var.zone
  service_account_email    = "abfs-server@${var.project_id}.iam.gserviceaccount.com"
  subnetwork               = "sdv-subnet"
  abfs_docker_image_uri    = var.abfs_docker_image_uri
  abfs_license             = var.abfs_license
  abfs_server_machine_type = var.abfs_server_machine_type
  abfs_datadisk_size_gb    = var.abfs_server_datadisk_size_gb
  abfs_datadisk_type       = var.abfs_server_datadisk_type
  abfs_server_name         = "abfs-server"
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
