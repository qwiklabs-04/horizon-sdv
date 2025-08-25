#!/usr/bin/env bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
TFVARS_JSON_FILE_PATH="$2"
CONFIRM_DELETE="$3"
REMOTE_TFVARS_JSON="output.tfvars.json"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"

# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "$TF_BACKEND_BUCKET" "$TFVARS_JSON_FILE_PATH"

# Extract terraform directory path
TF_DIR=$(dirname "${TFVARS_JSON_FILE_PATH}")
# Extract tfvars file name
TFVARS_JSON_FILE=$(basename "$TFVARS_JSON_FILE_PATH")

# Check if the deletion parameter (CONFIRM_DELETE) is checked
[[ "${CONFIRM_DELETE}" != "true" ]] && log_error "Skipping destroy. CONFIRM_DELETE parameter is not set to true."

# Change directory temporarily (for terraform)
pushd "$TF_DIR" > /dev/null || log_error "Cannot cd to ${TF_DIR}"

# ------ JSON Helpers ------

input_cloud_ws_workstation_name=$(get_json_value_by_key_at_path "$TFVARS_JSON_FILE" "." "input_sdv_cloud_ws_workstation_name")

remove_key_from_json_at_path "$TFVARS_JSON_FILE" "." "input_sdv_cloud_ws_workstation_name"

# ------Terraform workflow begins------

run_terraform_init "${TF_BACKEND_BUCKET}"
get_existing_workstations > "${REMOTE_TFVARS_JSON}"

if ! check_key_exists_in_json_at_path "${REMOTE_TFVARS_JSON}" "." "$input_cloud_ws_workstation_name"; then
  log_error "Workstation not found."
fi

remove_key_from_json_at_path "${REMOTE_TFVARS_JSON}" "." "${input_cloud_ws_workstation_name}"
merge_json_into_path "${TFVARS_JSON_FILE}" ".workstations" "${REMOTE_TFVARS_JSON}"

run_terraform_apply "${TFVARS_JSON_FILE}"

# Exit terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
