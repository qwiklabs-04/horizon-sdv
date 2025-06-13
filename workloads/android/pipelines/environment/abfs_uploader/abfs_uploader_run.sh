#!/usr/bin/env bash

# Copyright (c) 2025 Accenture, All Rights Reserved.
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

# Include common functions and variables.
# shellcheck disable=SC1091

function abfs_uploader_run() {
  echo "ABFS Uploader Run"

  export TF_VAR_project_id=${CLOUD_PROJECT}
  export TF_VAR_region=${CLOUD_REGION}
  export TF_VAR_zone=${CLOUD_ZONE}
  export TF_VAR_abfs_gerrit_uploader_count=1
  export TF_VAR_abfs_gerrit_uploader_machine_type="n2d-standard-4"
  export TF_VAR_abfs_gerrit_uploader_datadisk_size_gb="1024"
  export TF_VAR_abfs_gerrit_uploader_datadisk_type="pd-balanced"
  export TF_VAR_abfs_docker_image_uri="europe-docker.pkg.dev/abfs-binaries/abfs-containers-alpha/abfs-alpha:latest"
  export TF_VAR_abfs_gerrit_uploader_manifest_server="android.googlesource.com"
  export TF_VAR_abfs_gerrit_uploader_git_branch="[\"main\"]"
  export TF_VAR_abfs_manifest_file="default.xml"
  export TF_VAR_abfs_license=$(echo ABFS_LICENSE_B64 | base64 -d)

  terraform init
  terraform plan
}

abfs_uploader_run
