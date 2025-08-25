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


# ------Functions------

# Function to get list (names) of all Workstations from tfstate
get_workstations_list() {
  local workstations_tfstate_json_file="$1"

  log_info "Filtering list of all Workstations from tfstate JSON file '${workstations_tfstate_json_file}'..."

  jq -r '
    .values.root_module.resources // []
    | map(select(.type == "google_workstations_workstation" and .mode == "managed"))
    | map(.index)
    | .[]
  ' "${workstations_tfstate_json_file}" || log_error "Failed to run jq: invalid JSON while filtering list of all Workstations from tfstate JSON file '${workstations_tfstate_json_file}'..."
}


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

print_header "CLOUD WORKSTATION: LIST WORKSTATIONS"

run_terraform_init "$TF_BACKEND_BUCKET"


# ------Extract Workstations------

# Store WS tfstate in a file
export_tfstate_to_file "$WORKSTATIONS_TFSTATE_JSON_FILE"
log_info "Exported WS Workstations tfstate JSON to file: '${WORKSTATIONS_TFSTATE_JSON_FILE}'."

# Extract all Workstations list from tfstate
workstations_list=$(get_workstations_list "$WORKSTATIONS_TFSTATE_JSON_FILE")

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