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

# Description:
# Store OpenBSW targets to artifact area.
#
# Optional variables:
#  - OPENBSW_ARTIFACT_STORAGE_SOLUTION: the persistent storage location for
#        artifacts (GCS_BUCKET default).
#  - OPENBSW_ARTIFACT_ROOT_NAME: the name of the bucket to store artifacts.
#

# Include common functions and variables.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")"/bsw_environment.sh "$0"

# If the bucket does not exist, it is created.
# shellcheck disable=SC2317
function gcs_bucket() {
    local -r bucket_name="gs://${OPENBSW_ARTIFACT_ROOT_NAME}"
    # Replace spaces in Jenkins Job Name
    BUCKET_FOLDER="${JOB_NAME// /_}"
    local -r destination="${bucket_name}/${BUCKET_FOLDER}/${OPENBSW_BUILD_NUMBER}"
    local -r cloud_url="https://console.cloud.google.com/storage/browser/${OPENBSW_ARTIFACT_ROOT_NAME}/${BUCKET_FOLDER}/${OPENBSW_BUILD_NUMBER}"
    local -r artifacts_summary="${ORIG_WORKSPACE}/openbsw-${OPENBSW_BUILD_NUMBER}-artifacts.txt"

    # Remove the old artifacts
    gcloud storage rm -r "${destination}" || true

    # Wait for old artifacts to be removed.
    # Note: belts and braces because removal used to take time and appear to run in background. Now rm finishes cleanly.
    local -i attempts=0
    local -i max_attempts=10
    while gcloud storage ls "${destination}" &> /dev/null; do
        sleep 1.0
        ((attempts++))
        if [ "${attempts}" -gt "${max_attempts}" ]; then
            echo "ERROR: ${destination} still exists after ${max_attempts}s." >&2
            # Brute force just let it continue.
            break
        fi
    done

    rm -f "${artifacts_summary}"

    # Print download URL links in console log and file..
    echo ""
    echo "Artifacts stored in ${destination}" | tee -a "${artifacts_summary}"
    echo "Bucket URL: ${cloud_url}" | tee -a "${artifacts_summary}"
    echo "" | tee -a "${artifacts_summary}"

    # Copy artifacts to Google Cloud Storage bucket
    echo "Storing artifacts to bucket ${bucket_name}"
    for artifact in "${OPENBSW_ARTIFACT_LIST[@]}"; do
        for file in ${artifact}; do
            # Look for wildcard files.
            if [ -e "${file}" ]; then
                [ -d "${file}" ] && recurse="-r" || recurse=""
                # Copy the artifact to the bucket
                gcloud storage cp "${recurse}" "${file}" "${destination}"/ || true
                echo "Copied ${file} to ${destination}"
                # shellcheck disable=SC2086
                filename=$(echo ${file} | awk -F / '{print $NF}')
                echo "    gcloud storage cp ${recurse} ${destination}/${filename} ." | tee -a "${artifacts_summary}"
            fi
        done
    done
    echo "Artifacts summary:"
    cat "${artifacts_summary}"
}

#
# A noop function that does nothing.
#
# This function is used when the OPENBSW_ARTIFACT_STORAGE_SOLUTION is not
# supported. It prints a message to indicate that the artifacts are not
# being stored to any storage solution.
# shellcheck disable=SC2317
function noop() {
    echo "Noop: skipping artifact stored to ${OPENBSW_ARTIFACT_STORAGE_SOLUTION}" >&2
    for artifact in "${OPENBSW_ARTIFACT_LIST[@]}"; do
        echo "Skipping copy of ${artifact}" >&2
    done
}

#
# Storage selection.
#
# This case statement sets the OPENBSW_ARTIFACT_STORAGE_SOLUTION_FUNCTION
# variable to the appropriate function to call to store artifacts to
# the given storage solution.
case "${OPENBSW_ARTIFACT_STORAGE_SOLUTION}" in
    GCS_BUCKET)
        OPENBSW_ARTIFACT_STORAGE_SOLUTION_FUNCTION=gcs_bucket
        ;;
    *)
        OPENBSW_ARTIFACT_STORAGE_SOLUTION_FUNCTION=noop
        ;;
esac

# Store artifacts to artifact storage.
if [ -n "${OPENBSW_ARTIFACT_STORAGE_SOLUTION}" ] && [ -n "${OPENBSW_BUILD_NUMBER}" ]; then
    if [ ${#OPENBSW_ARTIFACT_LIST[@]} -gt 0 ]; then
        "${OPENBSW_ARTIFACT_STORAGE_SOLUTION_FUNCTION}"
    else
        echo "No artifacts to store to ${OPENBSW_ARTIFACT_STORAGE_SOLUTION}, ignored."
    fi
else
    # If not running from Jenkins, just NOOP!
    noop
fi

# Post storage commands.
echo "Post storage commands:"
for command in "${POST_STORAGE_COMMANDS[@]}"; do
    echo "${command}"
    eval "${command}"
done

# Return result
exit $?
