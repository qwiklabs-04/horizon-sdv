#!/usr/bin/env bash

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

# Capture the arguments passed to the script
MIRROR_ROOT_SUBDIR_PATH="$1"
MIRROR_DIR="$2"
MIRROR_MANIFEST_URL="$3"
MIRROR_MANIFEST_REF="$4"
MIRROR_MANIFEST_FILE="$5"
BUILD_USER="$6"

METADATA_FILE_NAME="metadata.yaml"
METADATA_FILE_FULL_PATH="${MIRROR_ROOT_SUBDIR_PATH}/${METADATA_FILE_NAME}"
MIRROR_DIR_FULL_PATH="${MIRROR_ROOT_SUBDIR_PATH}/${MIRROR_DIR}"

METADATA_FILE_ROOT_KEY=$(basename "${MIRROR_ROOT_SUBDIR_PATH}")
SYNC_TYPE="created"
SYNC_MIRROR_LOG_FILE_PATH="/tmp/sync_mirror.log"
GIT_LOCK_ERR_PATTERN="cannot lock ref 'refs/heads/.*.lock': File exists"

# Import shared utils
source "$(dirname "$0")/../utils/utils.sh"

# ------Initial Checks and Setup------

# Create mirror root subdirectory, if it does not exist
if ! check_directory_exists "${MIRROR_ROOT_SUBDIR_PATH}"; then
  create_directory "${MIRROR_ROOT_SUBDIR_PATH}"
fi

# Create metadata file for storing mirror details, if it does not exist
if ! check_file_exists "${METADATA_FILE_FULL_PATH}"; then
  log_info "This is the first mirror setup..."
  create_metadata_file_with_root_key "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}"
fi

# Create new input mirror directory, if it does not exist
if ! check_directory_exists "${MIRROR_DIR_FULL_PATH}"; then
  create_directory "${MIRROR_DIR_FULL_PATH}"
fi

# Add new mirror details to metadata file, if entry does not exist
if ! check_mirror_metadata_entry_exists "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}"; then
  insert_new_mirror_metadata_entry "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "${MIRROR_MANIFEST_URL}" "${MIRROR_MANIFEST_REF}" "${MIRROR_MANIFEST_FILE}" "${BUILD_USER}"
fi

# Change directory temporarily to input mirror directory
pushd "${MIRROR_DIR_FULL_PATH}" > /dev/null || log_error "Cannot cd to ${MIRROR_DIR_FULL_PATH}"


# ------Mirror workflow begins------

print_header "AOSP MIRROR SETUP: SYNC MIRROR"

log_info "Storage info for AOSP Mirror PVC before sync:"
get_aosp_mirror_pvc_storage_info "${MIRROR_ROOT_SUBDIR_PATH}"

# Check if .repo directory exists
if ! check_directory_exists "${MIRROR_DIR_FULL_PATH}/.repo"; then
  initialise_new_repo "${MIRROR_DIR_FULL_PATH}" "${MIRROR_MANIFEST_URL}" "${MIRROR_MANIFEST_REF}" "${MIRROR_MANIFEST_FILE}"
else
  log_info "'.repo' folder found in directory '${MIRROR_DIR_FULL_PATH}'. Reusing existing repo. Updating mirror with manifest at '${MIRROR_MANIFEST_URL}'..."

  SYNC_TYPE="updated"

  # Check if manifest URL has changed
  if ! match_mirror_manifest_url_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "${MIRROR_MANIFEST_URL}"; then
    log_error "You cannot change the manifest URL of an existing mirror.\n Please create a new mirror instead (in different directory)."
  fi
fi

update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "syncing"

# Sync the mirror and handle git lock file errors if any
if ! sync_mirror "${MIRROR_DIR_FULL_PATH}" "${MIRROR_MANIFEST_URL}" "${MIRROR_MANIFEST_REF}" "${MIRROR_MANIFEST_FILE}" "${SYNC_TYPE}" | tee "${SYNC_MIRROR_LOG_FILE_PATH}"; then
  update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "error"

  log_warning "Mirror sync failed. Checking for git lock file errors..."
  if grep -qE "${GIT_LOCK_ERR_PATTERN}" "${SYNC_MIRROR_LOG_FILE_PATH}"; then
    log_warning "Git lock file error encountered during sync. Attempting to clean up lock files and retry sync..."

    remove_stale_git_locks # takes around 20-30 mins for full cleanup
    
    log_info "Cleaned up lock files. Retrying mirror sync..."
    update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "syncing"

    # Retry sync 2nd time
    if ! sync_mirror "${MIRROR_DIR_FULL_PATH}" "${MIRROR_MANIFEST_URL}" "${MIRROR_MANIFEST_REF}" "${MIRROR_MANIFEST_FILE}" "${SYNC_TYPE}"; then
      # If 2nd sync fails, mark as error in metadata and exit
      update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "error"
      log_error "Mirror sync failed again on 2nd attempt after cleaning git lock files."
    fi
  else
    # If error is not due to git lock files, mark as error in metadata and exit
    update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "error"
    log_error "Mirror sync failed entirely and could not be recovered."
  fi
fi
# If we reach here, sync was successful (either 1st or 2nd try)
update_mirror_sync_status_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "ready"

update_mirror_last_successful_sync_time_in_metadata "${METADATA_FILE_FULL_PATH}" "${METADATA_FILE_ROOT_KEY}" "${MIRROR_DIR}" "$(date)"

log_info "Storage info for AOSP Mirror PVC after sync:"
get_aosp_mirror_pvc_storage_info "${MIRROR_ROOT_SUBDIR_PATH}"

# Exit AOSP Mirror PVC mount path in container
popd > /dev/null || log_error "Failed to return to the original working directory."
exit 0
