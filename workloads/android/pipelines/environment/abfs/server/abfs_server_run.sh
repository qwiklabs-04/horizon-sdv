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

function abfs_override_tf() {
  cat > main_override.tf <<EOL
module "abfs-server" {
  source = "git::${TERRAFORM_GITHUB_URL}//modules/server?ref=${TERRAFORM_GITHUB_VERSION}"
}
EOL
}

function abfs_server_run() {
  echo "ABFS Server Run"

  export TF_VAR_project_id="${CLOUD_PROJECT}"
  export TF_VAR_region="${CLOUD_REGION}"
  export TF_VAR_zone="${CLOUD_ZONE}"
  export TF_VAR_sdv_network="sdv-network"
  export TF_VAR_abfs_server_machine_type="${SERVER_MACHINE_TYPE}"
  export TF_VAR_abfs_docker_image_uri="${DOCKER_REGISTRY_NAME}"
  export TF_VAR_abfs_license
  # Workaround because Jenkins is not retrieving the password correctly.
  # TF_VAR_abfs_license="$(echo "${ABFS_LICENSE_B64}" | base64 -d)"
  TF_VAR_abfs_license=$(kubectl get secrets -n jenkins ${KUBERNETES_SECRET_NAME}  -o json | jq -r '.data.password' | base64 -d)

  terraform init -backend-config bucket="${CLOUD_BACKEND_BUCKET}" -upgrade

  if [ "${ABFS_TERRAFORM_ACTION}" = "APPLY" ]; then
    terraform plan
    terraform apply -auto-approve
  elif [ "${ABFS_TERRAFORM_ACTION}" = "DESTROY" ]; then
    terraform plan -destroy
    terraform destroy --auto-approve
  elif [ "${ABFS_TERRAFORM_ACTION}" = "START" ]; then
    gcloud compute instances start abfs-server --zone="${CLOUD_ZONE}"
  elif [ "${ABFS_TERRAFORM_ACTION}" = "STOP" ]; then
    gcloud compute instances stop abfs-server --zone="${CLOUD_ZONE}"
  elif [ "${ABFS_TERRAFORM_ACTION}" = "RESTART" ]; then
    gcloud compute instances reset abfs-server --zone="${CLOUD_ZONE}"
  else
    echo "WRONG ACTION"
  fi
}

function abfs_server_update_schema() {
  git clone "${TERRAFORM_GITHUB_URL}"
  REPO_DIRECTORY=$(basename "${TERRAFORM_GITHUB_URL}" .git)
  cd "${REPO_DIRECTORY}" || exit
  git checkout "${TERRAFORM_GITHUB_VERSION}"
  if [ -z "$(gcloud --project "${CLOUD_PROJECT}" spanner databases ddl describe --instance abfs abfs)" ]; then
    gcloud --project "${CLOUD_PROJECT}" spanner databases ddl update --instance abfs abfs --ddl-file "${SPANNER_DDL_FILE}"
  else
    if [ "${ABFS_TERRAFORM_ACTION}" = "DESTROY" ]; then
      # Remove Spanner DB.
      yes Y | gcloud --project "${CLOUD_PROJECT}" spanner databases delete abfs --instance=abfs || true
    fi
  fi
  cd - || true
  rm -rf "${REPO_DIRECTORY}"
}

abfs_override_tf
abfs_server_run
abfs_server_update_schema
