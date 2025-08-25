#!/bin/bash
set -eo pipefail

# Capture the arguments passed to the script
TF_BACKEND_BUCKET="$1"
WORKSTATIONS_TFVARS_JSON_FILE_PATH="$2"
CURRENT_USER="$3"

# Import shared utils
source "$(dirname "$0")/../../utils/terraform-utils.sh"

# Temporary file used to store tfstate JSON of Workstations
WORKSTATIONS_TFSTATE_JSON_FILE="workstations_tfstate.json"
# Temporary file used to store extracted workstations for specified user as JSON
EXISTING_WORKSTATIONS_FOR_USER_JSON_FILE="existing_workstations_for_user.json"


# ------Functions------

# Function to get list (names) of all Workstations from existing Workstations data for current user
get_workstations_list() {
  local existing_workstations_for_user_json_file="$1"

  [[ -z "$existing_workstations_for_user_json_file" ]] && log_error "Existing workstations for current user JSON file NOT provided as argument."
  [[ ! -f "$existing_workstations_for_user_json_file" ]] && log_error "File ${existing_workstations_for_user_json_file} does not exist."

  log_info "Filtering list of all Workstation names from existing Workstations data for current user '${CURRENT_USER}' from JSON file '${existing_workstations_for_user_json_file}'..."

  jq -r 'keys[]' "$existing_workstations_for_user_json_file" || log_error "Failed to run jq: invalid JSON while filtering Workstation names."
}


# ------Initial Checks and Setup------

validate_bucket_and_tfvars_args "$TF_BACKEND_BUCKET" "$WORKSTATIONS_TFVARS_JSON_FILE_PATH"

# Extract workstations terraform directory path
WORKSTATIONS_TF_DIR=$(dirname "${WORKSTATIONS_TFVARS_JSON_FILE_PATH}")
# Extract workstations tfvars file name
WORKSTATIONS_TFVARS_JSON_FILE=$(basename "$WORKSTATIONS_TFVARS_JSON_FILE_PATH")

# ---Check WS Cluster exists before proceeding---
# Extract Workstation Cluster terraform directory path
WS_CLUSTER_TF_DIR="${WORKSTATIONS_TF_DIR}/../cluster"
if ! check_ws_cluster_exists "$WS_CLUSTER_TF_DIR" "$TF_BACKEND_BUCKET"; then
  log_error "Workstation Cluster must exist before any operation of Workstations. Please ask your admin to run 'Create Cluster' job and then 'Create Configuration' job."
fi

# Change to workstations terraform directory temporarily
pushd "$WORKSTATIONS_TF_DIR" > /dev/null || log_error "Cannot cd to ${WORKSTATIONS_TF_DIR}"

print_header "CLOUD WORKSTATION: LIST WORKSTATIONS"

run_terraform_init "$TF_BACKEND_BUCKET"


# ------Extract Workstations------

# Store WS tfstate in a file
export_tfstate_to_file "$WORKSTATIONS_TFSTATE_JSON_FILE"
log_info "Exported WS Workstations tfstate JSON to file: '${WORKSTATIONS_TFSTATE_JSON_FILE}'."

# Extract existing Workstations for the current user
get_existing_workstations_for_user "$WORKSTATIONS_TFSTATE_JSON_FILE" "$CURRENT_USER" > "$EXISTING_WORKSTATIONS_FOR_USER_JSON_FILE" || log_error "Failed exporting existing Workstations for current user '${CURRENT_USER}' as JSON to file $EXISTING_WORKSTATIONS_FOR_USER_JSON_FILE"
log_info "Exported existing Workstations data for current user '${CURRENT_USER}' to file: '${EXISTING_WORKSTATIONS_FOR_USER_JSON_FILE}' - will now be used for further operations."

# Extract just Workstation names as list from existing Workstations data for the current user
workstations_list=$(get_workstations_list "$EXISTING_WORKSTATIONS_FOR_USER_JSON_FILE")

# ------Show Details of Workstation------

if [[ -z "$workstations_list" || "$workstations_list" == "{}" || "$workstations_list" == "null" ]]; then
  log_warning "NO Workstations found."
else
  log_success "Workstations found. --- List of Workstations:"
  echo "$workstations_list" | print_result
fi

# Exit workstation terraform directory
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0