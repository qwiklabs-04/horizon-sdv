# Copyright (c) 2025 Accenture, All Rights Reserved.
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

# Latest stable.
FROM --platform=linux/amd64 debian:12

ARG TERRAFORM_CATEGORY

# Install packages required for building AAOSP targets.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    apt-transport-https ca-certificates \
    gnupg software-properties-common curl git sudo jq openssh-client && \
    apt-get update -y && \
    rm -rf /var/lib/apt/lists/*

# Install numpy to speed up the SSH IAP tunelling
RUN $(gcloud info --format="value(basic.python_location)") -m pip install numpy

# Add USER and provide sudo access.
ARG USER=builder
RUN useradd -u 1000 -ms /bin/bash ${USER} && \
    passwd -d ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers

# Switch to user
USER ${USER}
WORKDIR /home/${USER}

# Configure git config (fake details) for Google repo.
RUN git config --global user.email "utilities.jenkins@dummy.com" && \
    git config --global user.name "Utilities Jenkins" && \
    git config --global color.ui false
