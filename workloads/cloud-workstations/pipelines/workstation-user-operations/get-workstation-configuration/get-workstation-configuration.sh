#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
TFVARS_JSON_FILE_PATH="$2"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"

# Temporary file used to store tfstate JSON of Workstations
WORKSTATIONS_TFSTATE_JSON_FILE="workstations_tfstate.json"
# Temporary file used to store extracted workstations and their IAM bindings JSON
EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE="existing_workstations_with_ws_users.json"

# Temporary file used to store tfstate JSON of WS Configs
WS_CONFIGS_TFSTATE_JSON_FILE="ws_configs_tfstate.json"
# Temporary file used to store extracted workstation configs and their IAM bindings JSON
EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE="existing_ws_configs_with_ws_admins.json"


# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "$TF_BACKEND_BUCKET" "$TFVARS_JSON_FILE_PATH"

# Extract terraform directory path
WORKSTATION_TF_DIR=$(dirname "${TFVARS_JSON_FILE_PATH}")
# Extract tfvars file name
TFVARS_JSON_FILE=$(basename "$TFVARS_JSON_FILE_PATH")

# ---Check WS Cluster exists before proceeding---
# Extract Workstation Cluster terraform directory path
WS_CLUSTER_TF_DIR="${WORKSTATION_TF_DIR}/../cluster"
if ! check_ws_cluster_exists "$WS_CLUSTER_TF_DIR" "$TF_BACKEND_BUCKET"; then
  log_error "Workstation Cluster must exist before any operation of Workstations. Please run 'Create Cluster' job first."
fi

# Change to workstation terraform directory temporarily
pushd "$WORKSTATION_TF_DIR" > /dev/null || log_error "Cannot cd to ${WORKSTATION_TF_DIR}"

print_header "CLOUD WORKSTATION: GET WORKSTATION CONFIG DETAILS"

run_terraform_init "$TF_BACKEND_BUCKET"


# ------Extract Workstation------

# Store WS tfstate in a file
export_tfstate_to_file "$WORKSTATIONS_TFSTATE_JSON_FILE"
log_info "Exported Workstations tfstate JSON to file: '${WORKSTATIONS_TFSTATE_JSON_FILE}'."

# Extract existing Workstations
get_existing_workstations_with_ws_users "$WORKSTATIONS_TFSTATE_JSON_FILE" > "$EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE" || log_error "Failed exporting existing Workstations and WS Users as JSON to file $EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE"
log_info "Exported existing Workstations and WS Users data to file: '${EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE}' - will now be used for further operations."

# Extract input Workstation name from tfvars file
input_workstation_name=$(get_json_value_by_key_at_path "$TFVARS_JSON_FILE" "." "sdv_cloud_ws_input_workstation_name")

# Prevent getting details of non-existent input Workstation among existing workstations
if ! check_key_exists_in_json_at_path "$EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE" "." "${input_workstation_name}"; then
  log_error "Please enter a workstation name that exists. Aborting..."
fi
log_info "Input Workstation: '${input_workstation_name}' found in existing Workstations."

# Extract WS Config name for input workstation name from existing Workstations file
ws_config_name=$(get_json_value_by_key_at_path "$EXISTING_WORKSTATIONS_WITH_WS_USERS_JSON_FILE" ".${input_workstation_name}" "ws_config_name")

# Exit workstation terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."


# ------Extract WS Config object from WS Config JSON------

CONFIG_TF_DIR="${WORKSTATION_TF_DIR}/../config"
# Change directory temporarily to Config terraform folder
pushd "$CONFIG_TF_DIR" > /dev/null || log_error "Cannot cd to ${CONFIG_TF_DIR}"

run_terraform_init "$TF_BACKEND_BUCKET"

# Store WS Config tfstate in a file
export_tfstate_to_file "$WS_CONFIGS_TFSTATE_JSON_FILE"
log_info "Exported WS Config tfstate JSON to file: '${WS_CONFIGS_TFSTATE_JSON_FILE}'."

# Get existing WS Configs
get_existing_ws_configs_with_ws_admins "$WS_CONFIGS_TFSTATE_JSON_FILE" > "$EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE" || log_error "Failed exporting existing workstation Configs and WS Admins as JSON to file $EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE"
log_info "Exported existing WS Configs data to file: '${EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE}' - will now be used for further operations."

# Extract WS Config object from existing WS Configs file
ws_config_details_json=$(get_json_value_by_key_at_path "$EXISTING_WS_CONFIGS_WITH_WS_ADMINS_JSON_FILE" "." "$ws_config_name")

# Exit terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."

# ------Show Details of WS Config------

if [[ -z "$ws_config_details_json" || "$ws_config_details_json" == "{}" || "$ws_config_details_json" == "null" ]]; then
  log_warning "NO workstation Configuration found for input workstation name: '${input_workstation_name}'"
else
  log_success "Workstation Config '${ws_config_name}' found for input workstation: '${input_workstation_name}' --- Details of Config:"
  echo "$ws_config_details_json" | jq -C | print_result
fi

exit 0