#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
WS_CLUSTER_TFVARS_JSON_FILE_PATH="$2"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"


# ------Initial Checks and Setup------


validate_bucket_and_tfvars_args "${TF_BACKEND_BUCKET}" "${WS_CLUSTER_TFVARS_JSON_FILE_PATH}"

# Extract terraform directory path
WS_CLUSTER_TF_DIR=$(dirname "${WS_CLUSTER_TFVARS_JSON_FILE_PATH}")
# Extract tfvars file name
WS_CLUSTER_TFVARS_JSON_FILE=$(basename "$WS_CLUSTER_TFVARS_JSON_FILE_PATH")

# ---Check WS Cluster exists before proceeding---
if ! check_ws_cluster_exists "$WS_CLUSTER_TF_DIR" "$TF_BACKEND_BUCKET"; then
  log_error "Workstation Cluster does NOT exist. Please run 'Create Cluster' job first."
fi

# Change directory temporarily to WS Cluster for terraform
pushd "$WS_CLUSTER_TF_DIR" > /dev/null || log_error "Cannot cd to ${WS_CLUSTER_TF_DIR}"

# ------Terraform workflow begins------

print_header "CLOUD WORKSTATION: DELETE CLUSTER"

run_terraform_init "${TF_BACKEND_BUCKET}"

run_terraform_destroy "${WS_CLUSTER_TFVARS_JSON_FILE}"

# Exit Cluster terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
