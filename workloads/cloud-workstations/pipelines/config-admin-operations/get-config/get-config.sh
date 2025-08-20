#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
TFVARS_JSON_FILE_PATH="$2"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"

# Temporary file used to store tfstate JSON of WS Configs
WS_CONFIGS_TFSTATE_JSON_FILE="ws_configs_tfstate.json"
# Temporary file used to store extracted workstation configs and their IAM bindings JSON
EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE="existing_ws_configs_with_ws_admins.json"


# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "$TF_BACKEND_BUCKET" "$TFVARS_JSON_FILE_PATH"

# Extract terraform directory path
TF_DIR=$(dirname "${TFVARS_JSON_FILE_PATH}")
# Extract tfvars file name
TFVARS_JSON_FILE=$(basename "$TFVARS_JSON_FILE_PATH")

# ---Check WS Cluster exists before proceeding---
# Extract Workstation Cluster terraform directory path
WS_CLUSTER_TF_DIR="${TF_DIR}/../cluster"
if ! check_ws_cluster_exists "$WS_CLUSTER_TF_DIR" "$TF_BACKEND_BUCKET"; then
  log_error "Workstation Cluster must exist before any operation of Workstation Config. Please run 'Create Cluster' job first."
fi

# Change directory temporarily (for terraform)
pushd "$TF_DIR" > /dev/null || log_error "Cannot cd to ${TF_DIR}"

print_header "CLOUD WORKSTATION: GET CONFIG DETAILS"

run_terraform_init "$TF_BACKEND_BUCKET"


# ------Extract WS Config------

# Store WS Config tfstate in a file
export_tfstate_to_file "$WS_CONFIGS_TFSTATE_JSON_FILE"
log_info "Exported WS Config tfstate JSON to file: '${WS_CONFIGS_TFSTATE_JSON_FILE}'."

# Extract existing WS Configs
get_existing_ws_configs_with_ws_admins "$WS_CONFIGS_TFSTATE_JSON_FILE" > "$EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE" || log_error "Failed exporting existing workstation Configs and WS Admins as JSON to file $EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE"
log_info "Exported existing WS Configs data to file: '${EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE}' - will now be used for further operations."

# Extract input WS Config name from tfvars file
input_ws_config_name=$(get_json_value_by_key_at_path "$TFVARS_JSON_FILE" "." "sdv_cloud_ws_input_config_name")

# Prevent getting details of non-existent input WS Config among existing WS Configs
if ! check_key_exists_in_json_at_path "$EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE" "." "${input_ws_config_name}"; then
  log_error "Please enter a workstation Configuration name that exists. Aborting..."
fi
log_info "Input WS Config: '${input_ws_config_name}' found in existing WS Configs."

# Extract input WS Config object from existing WS Configs file
input_ws_config_details_json=$(get_json_value_by_key_at_path "$EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE" "." "$input_ws_config_name")


# ------Show Details of input WS Config------

log_success "Workstation Config '${input_ws_config_name}' Details:"
echo "$input_ws_config_details_json" | jq -C | print_result

# Exit terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
