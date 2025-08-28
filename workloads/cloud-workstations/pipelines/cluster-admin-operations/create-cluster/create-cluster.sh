#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
WS_CLUSTER_TFVARS_JSON_FILE_PATH="$2"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"


# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "$TF_BACKEND_BUCKET" "$WS_CLUSTER_TFVARS_JSON_FILE_PATH"

# Extract Cluster terraform directory path
WS_CLUSTER_TF_DIR=$(dirname "${WS_CLUSTER_TFVARS_JSON_FILE_PATH}")
# Extract Cluster tfvars file name
WS_CLUSTER_TFVARS_JSON_FILE=$(basename "$WS_CLUSTER_TFVARS_JSON_FILE_PATH")

# ---Check WS Cluster already exists before proceeding---
if check_ws_cluster_exists "$WS_CLUSTER_TF_DIR" "$TF_BACKEND_BUCKET"; then
  log_error "Workstation Cluster exists ALREADY. Skipping..."
fi

# Change directory temporarily to WS Cluster terraform
pushd "$WS_CLUSTER_TF_DIR" > /dev/null || log_error "Cannot cd to ${WS_CLUSTER_TF_DIR}"


# ------Terraform workflow begins------

print_header "CLOUD WORKSTATION: CREATE CLUSTER"

run_terraform_init "${TF_BACKEND_BUCKET}"

run_terraform_apply "${WS_CLUSTER_TFVARS_JSON_FILE}"


# Exit Cluster terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
