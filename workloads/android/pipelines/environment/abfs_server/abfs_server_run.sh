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

function abfs_server_run() {
  echo "ABFS Server Run"

  export TF_VAR_project_id=${CLOUD_PROJECT}
  export TF_VAR_region=${CLOUD_REGION}
  export TF_VAR_zone=${CLOUD_ZONE}
  export TF_VAR_sdv_network="sdv-network"
  export TF_VAR_abfs_server_machine_type=${SERVER_MACHINE_TYPE}
  export TF_VAR_abfs_docker_image_uri="europe-docker.pkg.dev/abfs-binaries/abfs-containers-alpha/abfs-alpha:latest"
  export TF_VAR_abfs_license=$(echo $ABFS_LICENSE_B64 | base64 -d)

  terraform init -backend-config bucket=${CLOUD_BACKEND_BUCKET} -upgrade

  if [ ${ABFS_TERRAFORM_ACTION} = "APPLY" ]; then
    terraform plan
    terraform apply -auto-approve
  elif [ ${ABFS_TERRAFORM_ACTION} = "DESTROY" ]; then
    terraform plan -destroy
    terraform destroy --auto-approve
  elif [ ${ABFS_TERRAFORM_ACTION} = "START" ]; then
    gcloud compute instances start abfs-server --zone=${CLOUD_ZONE}
  elif [ ${ABFS_TERRAFORM_ACTION}} = "STOP" ]; then
    gcloud compute instances stop abfs-server --zone=${CLOUD_ZONE}
  elif [ ${ABFS_TERRAFORM_ACTION} = "RESTART" ]; then
    gcloud compute instances reset abfs-server --zone=${CLOUD_ZONE}
  else
    echo "WRONG ACTION"
  fi
}

function abfs_server_update_schema() {
  git clone https://github.com/terraform-google-modules/terraform-google-abfs.git
  cd terraform-google-abfs
  git checkout 961f5aa3c3be87a242597cbd4bc08821f28a7085
  if [ -z "$(gcloud --project ${CLOUD_PROJECT} spanner databases ddl describe --instance abfs abfs)" ]; then
    gcloud --project ${CLOUD_PROJECT} spanner databases ddl update --instance abfs abfs --ddl-file files/schemas/0.0.31-schema.sql
  fi
}

abfs_server_run
abfs_server_update_schema
