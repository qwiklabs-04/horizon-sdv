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
# Configuration file containing variables for the "sdv-gke-cluster" module.

variable "project_id" {
  description = "Define the project id"
  type        = string
}

variable "zone" {
  description = "Name of the zone"
  type        = string
}

variable "sdv_network" {
  description = "Name of the network"
  type        = string
}

variable "subnetwork" {
  description = "Name of the subnetwork"
  type        = string
}

variable "abfs_license" {
  description = "Define the ABFS license"
  type        = string
}

variable "abfs_server_machine_type" {
  description = "Define the machine type of the ABFS server"
  type        = string
  default     = "n2-highmem-2"
}

variable "abfs_datadisk_size_gb" {
  description = "Define the ABFS server datadisk size in GB"
  type        = string
  default     = "3000"
}

variable "abfs_datadisk_type" {
  description = "Define the ABFS server datadisk type"
  type        = string
  default     = "pd-balanced"
}

