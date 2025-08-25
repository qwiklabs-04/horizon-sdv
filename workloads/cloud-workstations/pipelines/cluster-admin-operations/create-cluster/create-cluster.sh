#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
TFVARS_FILE_PATH="$2"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"


# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "${TF_BACKEND_BUCKET}" "${TFVARS_FILE_PATH}"

# Extract terraform directory path
TF_DIR=$(dirname "${TFVARS_FILE_PATH}")
# Extract tfvars file name
TFVARS_FILE=$(basename "$TFVARS_FILE_PATH")

# Change directory temporarily (for terraform)
pushd "$TF_DIR" > /dev/null || log_error "Cannot cd to ${TF_DIR}"


# ------Terraform workflow begins------

print_header "CLOUD WORKSTATION: CREATE CLUSTER"

run_terraform_init "${TF_BACKEND_BUCKET}"

run_terraform_apply "${TFVARS_FILE}"


# Exit terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
