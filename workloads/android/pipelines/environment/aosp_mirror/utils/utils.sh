#!/bin/bash

# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
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

set -eo pipefail

# Google Repo Sync parallel jobs value (same as aaos builder)
REPO_SYNC_JOBS=${REPO_SYNC_JOBS:-2}

# ------Logging helper functions-------

# Function to print a header message
# Returns void
print_header() {
  echo
  echo "┌────────────────────────────────────────────────────────────────┐"
  printf "│ %-62s │\n" "$1"
  echo "└────────────────────────────────────────────────────────────────┘"
}

# # Function to print result messages with indentation
# # Returns void
# print_result() {
#   echo "┌─RESULT"
#   # Read and indent lines from stdin preserving colors and whitespace
#   while IFS= read -r line || [[ -n $line ]]; do
#     printf '    %s\n' "$line"
#   done
#   echo "└─"
# }

# Logging functions with different severity levels
log_info() { echo -e "\n [INFO] $1 \n" >&2; }
log_success() { echo -e "\n\u001B[32m [SUCCESS] $1 \u001B[0m\n" >&2; }
log_warning() { echo -e "\n\u001B[33m [WARNING] $1 \u001B[0m\n" >&2; }
log_error() { echo -e "\n\u001B[31m [ERROR] $1\u001B[0m" >&2; exit 1; } # Exits with status 1

# Function to calculate and return formatted elapsed time
# Returns formatted elapsed time string
get_formatted_elapsed_time() {
  local start_time_in_seconds=$1
  local end_time_in_seconds=$2
  local elapsed_time_in_seconds=$((end_time_in_seconds - start_time_in_seconds))
  local hours=$((elapsed_time_in_seconds / 3600))
  local remaining_seconds=$((elapsed_time_in_seconds % 3600))
  local minutes=$((remaining_seconds / 60))
  local seconds=$((remaining_seconds % 60))
  local formatted_elapsed_time=$(printf '%02dh %02dm %02ds' $hours $minutes $seconds)

  echo "$formatted_elapsed_time"
}

# ------Kubernetes helper functions-------

# Function to check if the AOSP Mirror PVC exists
# Returns boolean
check_aosp_mirror_pvc_exists() {
  local pvc_name=$1
  local namespace=$2

  log_info "Checking if PVC '${pvc_name}' exists in namespace '${namespace}'..."
  
  if ! kubectl get pvc "$pvc_name" -n "$namespace" &> /dev/null; then
    log_warning "PVC '${pvc_name}' not found in namespace '${namespace}'."
    return 1
  fi

  return 0
}

# Function to get storage info for AOSP Mirror PVC
# Returns void; exit 1 on failure
get_aosp_mirror_pvc_storage_info() {
  local mirror_pvc_mount_path_in_container=$1

  log_info "Fetching storage info for mirror PVC mounted at '${mirror_pvc_mount_path_in_container}'..."

  df "${mirror_pvc_mount_path_in_container}" -h || log_warning "Failed to fetch storage info for mirror PVC mounted at '${mirror_pvc_mount_path_in_container}'."
}

# ------Validation and Metadata Functions------

# Function to validate common args for all scripts
# Returns boolean
validate_bucket_and_tfvars_args() {
  local tf_backend_bucket="$1"
  local tfvars_json_file_path="$2"

  log_info "Validating arguments: TF Backend bucket and .tfvars file..."

  # Check if bucket name is provided as argument
  [[ -z "$tf_backend_bucket" ]] && log_error "TF Backend bucket name was not provided as an argument."
  # Check if .tfvars file name is provided as argument
  [[ -z "$tfvars_json_file_path" ]] && log_error ".tfvars file path was not provided as an argument."
  # Check if .tfvars file exists
  [[ ! -f "$tfvars_json_file_path" ]] && log_error "File ${tfvars_json_file_path} not found."

  return 0
}

# Function to check if given file exists
# Returns boolean
check_file_exists() {
  local file_path=$1
  local file_name=$(basename "$file_path")

  log_info "Checking if file '${file_name}' exists at path '${file_path}'..."

  if [[ ! -f "$file_path" ]]; then
    log_warning "File '${file_name}' NOT found at path '${file_path}'."
    return 1
  fi

  return 0
}

# Function to check if given directory exists
# Returns boolean
check_directory_exists() {
  local dir_path=$1
  local dir_name=$(basename "$dir_path")

  log_info "Checking if directory '${dir_name}' exists at path '${dir_path}'..."

  if [[ ! -d "$dir_path" ]]; then
    log_warning "Directory '${dir_name}' NOT found at path '${dir_path}'."
    return 1
  fi

  return 0
}

# Function to create new directory
# Returns void; exit 1 on failure
create_directory() {
  local dir_path=$1
  local dir_name=$(basename "$dir_path")

  log_info "Creating new directory '${dir_name}' at path '${dir_path}'..."

  mkdir -p "${dir_path}" || log_error "Failed to create directory at path '${dir_path}'."

  log_success "Created new directory '${dir_name}' at path '${dir_path}'."
}

# Function to create a new metadata file with just root key
# Returns void; exit 1 on failure
create_metadata_file_with_root_key() {
  local metadata_file_path=$1
  local root_key=$2

  log_info "Creating new metadata file at path '${metadata_file_path}'..."

  echo "${root_key}: {}" > "${metadata_file_path}" || log_error "Failed to create metadata file at path '${metadata_file_path}'."

  log_success "Created new metadata file at path '${metadata_file_path}'."
}

# Function to check if nested key for mirror exists in metadata file
# Returns boolean
check_mirror_metadata_entry_exists() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3

  log_info "Checking if metadata entry exists for mirror directory '$mirror_dir_name'..."

  local exists=$(yq ".${root_key} | has(\"${mirror_dir_name}\")" "${metadata_file_path}")
  if [[ "$exists" != "true" ]]; then
    log_warning "Metadata entry NOT found for mirror directory '$mirror_dir_name'."
    return 1
  fi

  return 0
}

# Function to insert new mirror details into metadata file
# Returns void; exit 1 on failure
insert_new_mirror_metadata_entry() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3
  local manifest_url=$4
  local manifest_ref=$5
  local manifest_file=$6
  local build_user=$7

  log_info "Inserting new metadata entry for mirror directory '${mirror_dir_name}'..."

  # Use yq to insert new mirror details under the root key
  yq "
    .${root_key}.${mirror_dir_name}.name = \"${mirror_dir_name}\" |
    .${root_key}.${mirror_dir_name}.type = \"repo\" |
    .${root_key}.${mirror_dir_name}.manifest_url = \"${manifest_url}\" |
    .${root_key}.${mirror_dir_name}.manifest_ref = \"${manifest_ref}\" |
    .${root_key}.${mirror_dir_name}.manifest_file = \"${manifest_file}\" |
    .${root_key}.${mirror_dir_name}.status = \"uninitialized\" |
    .${root_key}.${mirror_dir_name}.last_successful_sync_time = \"\" |
    .${root_key}.${mirror_dir_name}.created_by = \"${build_user}\"
  " --inplace "$metadata_file_path" || log_error "Failed to insert new mirror metadata entry into file '${metadata_file_path}'."

  log_success "Inserted new mirror metadata entry for mirror directory '${mirror_dir_name}' into file '${metadata_file_path}'."
}

# Function to check if input manifest URL matches existing manifest URL in metadata file
# Returns boolean
match_mirror_manifest_url_in_metadata() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3
  local input_manifest_url=$4
  local existing_manifest_url=""

  log_info "Checking if input manifest URL '$input_manifest_url' matches the existing manifest URL for mirror directory '${mirror_dir_name}'..."

  existing_manifest_url=$(yq ".${root_key}.${mirror_dir_name}.manifest_url" "${metadata_file_path}") || log_error "Failed to read manifest URL from metadata file '${metadata_file_path}'."

  if [[ "$existing_manifest_url" != "$input_manifest_url" ]]; then
    log_warning "Input Manifest URL '${input_manifest_url}' does NOT match with Existing Manifest URL '${existing_manifest_url}' for mirror directory '${mirror_dir_name}'."
    return 1
  fi

  log_info "Input Manifest URL '${input_manifest_url}' matches Existing Manifest URL '${existing_manifest_url}' for mirror directory '${mirror_dir_name}'."
  return 0
}

# Function to update mirror sync status in metadata file
# Internal use only
# Returns void; exit 1 on failure
update_mirror_sync_status_in_metadata() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3
  local sync_status=$4

  log_info "Updating sync status to '${sync_status}' for mirror directory '${mirror_dir_name}' in metadata file '${metadata_file_path}'..."

  # Check if given mirror directory exists in metadata file
  if ! check_mirror_metadata_entry_exists "${metadata_file_path}" "${root_key}" "${mirror_dir_name}"; then
    log_error "Cannot update sync status. Mirror directory '${mirror_dir_name}' does not exist in metadata file '${metadata_file_path}'."
  fi

  # Update the sync status field in metadata file
  yq "
    .${root_key}.${mirror_dir_name}.status = \"$sync_status\"
  " --inplace "${metadata_file_path}" || log_error "Failed to update mirror sync status in metadata file '${metadata_file_path}'."

  log_success "Updated sync status to '${sync_status}' for mirror directory '${mirror_dir_name}' in metadata file '${metadata_file_path}'."
}

# Function to update last successful sync time in metadata file
# Internal use only
# Returns void; exit 1 on failure
update_mirror_last_successful_sync_time_in_metadata() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3
  local last_successful_sync_time=$4

  log_info "Updating last successful sync time to '${last_successful_sync_time}' for mirror directory '${mirror_dir_name}' in metadata file '${metadata_file_path}'..."

  # Check if given mirror directory exists in metadata file
  if ! check_mirror_metadata_entry_exists "${metadata_file_path}" "${root_key}" "${mirror_dir_name}"; then
    log_error "Cannot update last successful sync time field. Mirror directory '${mirror_dir_name}' does not exist in metadata file '${metadata_file_path}'."
  fi

  # Update the last successful sync time field in metadata file
  yq "
    .${root_key}.${mirror_dir_name}.last_successful_sync_time = \"$last_successful_sync_time\"
  " --inplace "${metadata_file_path}" || log_error "Failed to update last successful sync time in metadata file '${metadata_file_path}'."

  log_success "Updated last successful sync time to '${last_successful_sync_time}' for mirror directory '${mirror_dir_name}' in metadata file '${metadata_file_path}'."
}

# Function to delete mirror directory
# Returns void; exit 1 on failure
delete_mirror_directory() {
  local mirror_dir_full_path=$1
  local mirror_dir_name=$(basename "$mirror_dir_full_path")

  log_info "Deleting mirror directory '${mirror_dir_name}' at path '${mirror_dir_full_path}'..."

  rm -rf "${mirror_dir_full_path}" || log_error "Failed to delete mirror directory: '${mirror_dir_full_path}'"

  log_success "Successfully deleted mirror directory: '${mirror_dir_full_path}'"
}

# Function to delete mirror entry from metadata file
# Returns void; exit 1 on failure
delete_mirror_entry_from_metadata() {
  local metadata_file_path=$1
  local root_key=$2
  local mirror_dir_name=$3

  # Check if given mirror directory exists in metadata file
  if ! check_mirror_metadata_entry_exists "${metadata_file_path}" "${root_key}" "${mirror_dir_name}"; then
    log_error "Cannot delete mirror entry. Mirror directory '${mirror_dir_name}' does not exist in metadata file '${metadata_file_path}'."
  fi

  log_info "Deleting entry for directory '${mirror_dir_name}' from metadata file '${metadata_file_path}'..."

  yq "
    del(.${root_key}.${mirror_dir_name})
  " --inplace "${metadata_file_path}" || log_error "Failed to delete entry for directory '${mirror_dir_name}' from metadata file '${metadata_file_path}'."

  log_success "Deleted entry for directory '${mirror_dir_name}' from metadata file '${metadata_file_path}'."
}

# ------Repo helper functions-------

# Function to remove stale git lock files
# Returns void; exit 1 on failure
remove_stale_git_locks() {
  local mirror_path=${1:-"."} # Default to current directory if no argument is provided

  log_info "Starting git lock file cleanup from any previous runs..."

  find "${mirror_path}" -name "*.lock" -print -delete || log_warning "Failed to cleanup some lock files, proceeding with sync."
}

# Function to initialize a new repo on local with mirror manifest
# Returns void; exit 1 on failure
initialise_new_repo() {
  local mirror_path=${1:-"."} # Default to current directory if no argument is provided
  local manifest_url=$2
  local manifest_ref=$3
  local manifest_file=$4

  log_info "Initializing new repo inside '${mirror_path}' with details:\n Manifest URL:'${manifest_url}'\n Manifest Ref:'${manifest_ref}'\n Manifest File:'${manifest_file}'..."

  cd "${mirror_path}" || log_error "Failed to cd into mirror path '${mirror_path}'."

  repo init \
  -u "${manifest_url}" \
  -b "${manifest_ref}" \
  -m "${manifest_file}" \
  --mirror || log_error "Failed to initialize repo with manifest at '${manifest_url}'."

  log_info "Removing unnecessary refs..."
  repo forall -c "git for-each-ref --format '%(refname)' refs/changes/ | xargs -n1 git update-ref -d" || log_error "Failed to remove unnecessary refs"
}

# Function to perform repo sync with Google's source
# Returns void; exit 1 on failure
sync_mirror() {
  local mirror_path=${1:-"."} # Default to current directory if no argument is provided
  local manifest_url=$2
  local manifest_ref=$3
  local manifest_file=$4
  local operation_type=${5:-"updated"} # Default to "updated" if no argument is provided

  local start_time_in_seconds=$(date +%s)
  local end_time_in_seconds
  local formatted_elapsed_time

  local jobs=$(( REPO_SYNC_JOBS < 1 ? 1 : REPO_SYNC_JOBS > $(nproc) ? $(nproc) : REPO_SYNC_JOBS ))

  log_info "Starting repo sync inside '${mirror_path}' with details:\n Manifest URL:'${manifest_url}'\n Manifest Ref:'${manifest_ref}'\n Manifest File:'${manifest_file}'\n Parallel jobs: ${jobs}\n Sync started at [$(date)]..."

  cd "${mirror_path}" || log_error "Failed to cd into mirror path '${mirror_path}'."

  repo sync \
    -j"${jobs}" \
    --optimized-fetch \
    --prune \
    --retry-fetches=3 \
    --auto-gc \
    --no-clone-bundle

  local sync_status=$?

  end_time_in_seconds=$(date +%s)
  formatted_elapsed_time=$(get_formatted_elapsed_time $start_time_in_seconds $end_time_in_seconds)

  if [[ $sync_status -ne 0 ]]; then
    log_error "Failed to perform repo sync. Time elapsed: [${formatted_elapsed_time}]"
  fi

  log_success "Repo sync completed at [$(date)].\n Time elapsed: [${formatted_elapsed_time}].\n Local AOSP mirror ${operation_type}."

  # log_info "Performing garbage collection..."
  # repo forall -c "git gc --aggressive --prune=all" || log_error "Failed to perform garbage collection post repo sync."
}


# ------Terraform workflow Functions-------

export TF_IN_AUTOMATION=1

# Function to initialize terraform
# Returns void; exit 1 on failure
run_terraform_init() {
  local backend_bucket=$1

  log_info "Initializing Terraform..."
  terraform init -backend-config="bucket=${backend_bucket}" || log_error "Terraform init failed"
}

# Function to apply terraform changes
# Returns void; exit 1 on failure
run_terraform_apply() {
  local tfvars_file=$1

  log_info "Applying changes..."
  terraform apply -auto-approve -var-file="${tfvars_file}" || log_error "Terraform apply failed."
}

# Function to destroy terraform-managed infrastructure
# Returns void; exit 1 on failure
run_terraform_destroy() {
  local tfvars_file=$1
  log_info "Running Terraform destroy..."
  terraform destroy -auto-approve -var-file="${tfvars_file}" || log_error "Terraform destroy failed."
}
