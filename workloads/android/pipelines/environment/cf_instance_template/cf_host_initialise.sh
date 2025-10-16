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
# Initialise Cuttlefish host instance.
#
# Script is only intended for use by cvd_create_instance_template.sh
# for installing host tools on the base VM instance which is used to
# create the CF instance template.

# Include common functions and variables.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")"/cf_environment.sh "$0"

declare -r JENKINS_USER="jenkins"

# Colours for logging.
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Check virtualization enabled.
function cuttlefish_virtualization() {
    if ! sudo find /dev -name kvm > /dev/null 2>&1; then
        echo -e "${RED}Error: virtualization not enabled${NC}"
        exit 1
    fi
}

# Install additional packages.
function cuttlefish_install_additional_packages() {
    local -a package_list=("default-jdk" "adb" "git" "npm" "aapt" "htop")

    echo -e "${GREEN}Installing additional packages.${NC}"

    # Ensure update to latest package list.
    sudo apt update -y
    for package in "${package_list[@]}"; do
        if ! dpkg -s "${package}" > /dev/null 2>&1; then
            echo -e "${GREEN}Installing ${package}${NC}"
            sudo apt install -y "${package}"
        else
            echo -e "${GREEN}${package} already installed${NC}"
        fi
    done

    echo -e "${ORANGE}Install version ${JAVA_VERSION}.${NC}"
    sudo apt-get update -y
    sudo apt-get install -y openjdk-17-jdk-headless || true

    echo -e "${GREEN} Java version:${NC}"
    java --version

    # Install Node version manager and nodejs.
    echo -e "${GREEN}Installing nodejs ${NODEJS_VERSION}${NC}"
    npm cache clean -f
    sudo npm install -g n
    sudo n "${NODEJS_VERSION}"
    sudo npm install -g wait-on
    sudo ln -sf /usr/local/bin/node  /usr/local/bin/nodejs || true

    # Show node version and path.
    which node
    node -v

    echo -e "${GREEN}Installing additional packages completed.${NC}"
}

# Disable unattended-upgrades
function disable_unattended_upgrades() {
    sudo systemctl status unattended-upgrades || true
    sudo apt remove -y --purge unattended-upgrades
    sudo apt autoremove -y
    sudo rm -rf /var/log/unattended-upgrades
}

# Download from local storage of official (http)
function download_cts() {
    local url="$1"
    local dest="$2"
    if [[ "${url}" == gs://* ]]; then
        CMD="gcloud storage cp ${url} ${dest}"
        echo "Download $CMD"
        su -l "${JENKINS_USER}" -c "eval $CMD"
    elif [[ "${url}" == http*  ]]; then
        CMD="wget -nv ${url} -O ${dest}"
        echo "Download $CMD"
        su -l "${JENKINS_USER}" -c "eval $CMD"
    else
        echo "echo 'Unknown URL scheme (${url})."
        exit 1
    fi
}

# Install CTS test harness on instance to avoid lengthy CTS runs.
function cuttlefish_install_cts() {
    echo -e "${GREEN}Installing CTS test harness ... ${NC}"
    local start=$SECONDS

    if [ ! -z "${CTS_ANDROID_16_URL}" ]; then
        su -l "${JENKINS_USER}" -c "mkdir -p android-cts_16"
        echo -e "${GREEN}Downloading.${NC} ${CTS_ANDROID_16_URL}. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        download_cts  "${CTS_ANDROID_16_URL}" android-cts_16.zip
        echo -e "${GREEN}Unpacking.${NC} android-cts_16.zip. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        su -l "${JENKINS_USER}" -c "unzip -q android-cts_16.zip -d android-cts_16"
        su -l "${JENKINS_USER}" -c "rm -f android-cts_16.zip"
    else
        echo -e "${ORANGE} Skipped Android 16 CTS, nothing to install.${NC}"
    fi

    if [ ! -z "${CTS_ANDROID_15_URL}" ]; then
        su -l "${JENKINS_USER}" -c "mkdir -p android-cts_15"
        echo -e "${GREEN}Downloading.${NC} ${CTS_ANDROID_15_URL}. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        download_cts  "${CTS_ANDROID_15_URL}" android-cts_15.zip
        echo -e "${GREEN}Unpacking.${NC} android-cts_15.zip. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        su -l "${JENKINS_USER}" -c "unzip -q android-cts_15.zip -d android-cts_15"
        su -l "${JENKINS_USER}" -c "rm -f android-cts_15.zip"
    else
        echo -e "${ORANGE} Skipped Android 15 CTS, nothing to install.${NC}"
    fi

    if [ ! -z "${CTS_ANDROID_14_URL}" ]; then
        su -l "${JENKINS_USER}" -c "mkdir -p android-cts_14"
        echo -e "${GREEN}Downloading.${NC} ${CTS_ANDROID_14_URL}. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        download_cts  "${CTS_ANDROID_14_URL}" android-cts_14.zip
        echo -e "${GREEN}Unpacking.${NC} android-cts_14.zip. ${ORANGE}This can take several minutes to complete, please wait!${NC}"
        su -l "${JENKINS_USER}" -c "unzip -q android-cts_14.zip -d android-cts_14"
        su -l "${JENKINS_USER}" -c "rm -f android-cts_14.zip"
    else
        echo -e "${ORANGE} Skipped Android 14 CTS, nothing to install.${NC}"
    fi
    # Force sync to ensure disk is updated.
    sync

    local elapsed=$(( SECONDS - start ))
    m=$(( elapsed / 60 ))
    s=$(( elapsed % 60 ))
    echo -e "${GREEN}Installing CTS test harness completed in ${m}m${s}s.${NC}"
}

# Install Cuttlefish prebuilts
function cuttlefish_install_prebuilt() {
    # Register the apt repository on Artifact Registry
    echo -e "${GREEN}Cuttlefish attempt prebuilt install on $1 ...${NC}"
    sudo curl -fsSL https://us-apt.pkg.dev/doc/repo-signing-key.gpg \
        -o /etc/apt/trusted.gpg.d/artifact-registry.asc
    sudo chmod a+r /etc/apt/trusted.gpg.d/artifact-registry.asc
    echo "deb https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts android-cuttlefish $1" \
        | sudo tee -a /etc/apt/sources.list.d/artifact-registry.list
    sudo cat /etc/apt/sources.list.d/artifact-registry.list
    sudo apt update -y

    if ! sudo apt install -y cuttlefish-base cuttlefish-user cuttlefish-orchestration; then
        echo -e "${RED}Failed to install prebuilt for revision ${1}${NC}"
        return 1
    else
        echo -e "${GREEN}Installed prebuilt for revision ${1}${NC}"
        return 0
    fi
}

# Add the user to the CVD groups.
function cuttlefish_user_groups() {
    declare -a cf_gids=(cvdnetwork kvm render)
    local -r gids=$(id -nG "$1")

    for gid in "${cf_gids[@]}"; do
        # This is most reliable method to check if group is present.
        if ! echo "${gids}" | grep -qw "${gid}"; then
            echo -e "${ORANGE}Group ${gid} is missing from user: ${1}${NC}"
            sudo usermod -aG "${gid}" "$1"
        fi
    done
}

function cuttlefish_jenkins_user() {
    # Delete any ubuntu default user (1000)
    # shellcheck disable=SC2046
    sudo userdel $(awk -F: '$3==1000{print $1}' /etc/passwd) > /dev/null 2>&1 || true
    sudo useradd -u 1000 -ms /bin/bash ${JENKINS_USER} > /dev/null 2>&1
    sudo passwd -d ${JENKINS_USER} > /dev/null 2>&1
    sudo usermod -aG google-sudoers ${JENKINS_USER} > /dev/null 2>&1
    cuttlefish_user_groups ${JENKINS_USER}
}

function cuttlefish_cleanup() {
    # Clean up
    cd ..
    rm -rf "${CUTTLEFISH_REPO_NAME}"
}

# Install the Cuttlefish packages.
function cuttlefish_install() {
    # Disable unattended-upgrades
    disable_unattended_upgrades

    # Install additional packages
    cuttlefish_install_additional_packages

    # Cuttlefish will request package restart, override mode.
    export NEEDRESTART_MODE=a
    # Prebuilts are only supported on X86_64 and main currently, fall through to build on error.
    if [ "${ANDROID_CUTTLEFISH_PREBUILT}" != "true" ] || ! cuttlefish_install_prebuilt "${CUTTLEFISH_REVISION}"; then
        echo -e "${GREEN}Cuttlefish Building from ${CUTTLEFISH_REVISION}.${NC}"; echo
        git clone "${CUTTLEFISH_REPO_URL}" -b "${CUTTLEFISH_REVISION}" > /dev/null 2>&1
        cd "${CUTTLEFISH_REPO_NAME}" || exit

        declare -r BUILD_SCRIPT=./tools/buildutils/build_packages.sh

        # Build and install the cuttlefish packages
        if ! [ -f "${BUILD_SCRIPT}" ]; then
            echo -e "${RED}Error: ${CUTTLEFISH_REVISION} does not support ${BUILD_SCRIPT}${NC}"
            echo -e "${RED}       Please choose a compatible version.${NC}"
            cuttlefish_cleanup
            exit 1
        else
            echo -e "${GREEN}Cuttlefish build script: ${BUILD_SCRIPT}${NC}"
            # Avoid restart issues
            # Build cuttlefish packages
            yes Y | "${BUILD_SCRIPT}"

            # Install the cuttlefish packages
            sudo apt install -y ./cuttlefish-base_*.deb ./cuttlefish-user_*.deb ./cuttlefish-orchestration*.deb

            # Clean up
            cuttlefish_cleanup
        fi
        echo -e "${GREEN}Cuttlefish Build process complete.${NC}"
    fi

    # Add groups to the user.
    cuttlefish_user_groups "$(whoami)"

    # Add jenkins user
    cuttlefish_jenkins_user

    # Install CTS
    if [ "$(uname -s)" = "Darwin" ]; then
        echo -e "${ORANGE}This script is only supported on Linux${NC}"
        echo -e "${ORANGE}   Ignore CTS download and install${NC}"
    else
        cuttlefish_install_cts
    fi
}

# Initialise or update Cuttlefish.
function cuttlefish_initialise() {

    # Check if virtualization is enabled.
    cuttlefish_virtualization

    # Check if cuttlefish is already installed
    echo -e "${GREEN}Installing Cuttlefish revision ${CUTTLEFISH_REVISION}${NC}"

    if ! dpkg -s cuttlefish-base > /dev/null 2>&1; then
        cuttlefish_install
    else
        if [ "${CUTTLEFISH_UPDATE}" = "true" ]; then
            echo -e "${ORANGE}Cuttlefish upgrade required.${NC}"
            # Remove and purge previous install.
            # Note: base will remove user, but remove just in case
            sudo apt remove -y cuttlefish-* > /dev/null 2>&1
            sudo apt autoremove -y > /dev/null 2>&1
            sudo dpkg --purge cuttlefish-base cuttlefish-user cuttlefish-orchestration > /dev/null 2>&1
            cuttlefish_install
        fi
    fi
    echo -e "${GREEN}Installing Cuttlefish revision ${CUTTLEFISH_REVISION} completed${NC}"
}

# Main program
cuttlefish_initialise
