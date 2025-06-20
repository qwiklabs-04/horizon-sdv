# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Description:
# Main configuration file for the "sdv-apis" module.
# This module enables the specified Google Cloud APIs from a provided list.

data "google_project" "project" {}

module "sdv_abfs_server" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-abfs.git//modules/server?ref=d28162880322f56eb49445ce89b0a9d1073a4677"

  project_id               = var.project_id
  zone                     = var.zone
  service_account_email    = "abfs-server@${var.project_id}.iam.gserviceaccount.com"
  subnetwork               = var.subnetwork
  abfs_docker_image_uri    = "europe-docker.pkg.dev/abfs-binaries/abfs-containers-alpha/abfs-alpha:latest"
  abfs_license             = var.abfs_license
  abfs_server_machine_type = var.abfs_server_machine_type
  abfs_datadisk_size_gb    = var.abfs_datadisk_size_gb
  abfs_datadisk_type       = var.abfs_datadisk_type
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
