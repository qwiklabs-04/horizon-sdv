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

# Latest stable.
FROM --platform=linux/amd64 debian:12

# Install packages required for building AAOSP targets.
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends apt-utils && \
  apt-get -y upgrade && \
  apt-get install -y --no-install-recommends \
  apt-transport-https ca-certificates \
  gnupg software-properties-common curl git sudo && \
  apt-get update -y && \
  rm -rf /var/lib/apt/lists/*

# The following installs gcloud sdk including gsutil required for uploading
# artifacts to Google Cloud Storage. Remove if using alternative storage.
# https://cloud.google.com/storage/docs/gsutil_install
# GCS:START
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt-get update -y && apt-get install -y google-cloud-cli kubectl
# GCS:END

# Install Terraform command tool
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
  apt-get update -y && apt-get install -y terraform && \
  apt-get -y clean

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
RUN git config --global user.email "aaosp.jenkins@dummy.com" && \
  git config --global user.name "AAOSP Jenkins" && \
  git config --global color.ui false
