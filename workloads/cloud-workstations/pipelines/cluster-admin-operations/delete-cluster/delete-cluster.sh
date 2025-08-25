#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
TFVARS_FILE_PATH="$2"
CONFIRM_DELETE="$3"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"


# ------Initial Checks and Setup------

# Check if the deletion parameter (CONFIRM_DELETE) is checked
[[ "${CONFIRM_DELETE}" != "true" ]] && log_error "Skipping destroy. CONFIRM_DELETE parameter is not set to true."

validate_bucket_and_tfvars_args "${TF_BACKEND_BUCKET}" "${TFVARS_FILE_PATH}"

# Extract terraform directory path
TF_DIR=$(dirname "${TFVARS_FILE_PATH}")
# Extract tfvars file name
TFVARS_FILE=$(basename "$TFVARS_FILE_PATH")

# Change directory temporarily (for terraform)
pushd "$TF_DIR" > /dev/null || log_error "Cannot cd to ${TF_DIR}"

# ------Terraform workflow begins------

print_header "CLOUD WORKSTATION: DELETE CLUSTER"

run_terraform_init "${TF_BACKEND_BUCKET}"

run_terraform_empty_state_check

run_terraform_destroy "${TFVARS_FILE}"

# Exit terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
