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

check_module_loaded() {
  local module_name="$1"
  local timeout="$2"
  local interval=1
  local elapsed=0

  if [[ -z "$module_name" || -z "$timeout" ]]; then
    echo "Usage: check_module_loaded <module_name> <timeout_seconds>"
    return 2
  fi

  while ((elapsed < timeout)); do
    if lsmod | grep -qw "$module_name"; then
      echo "Module '$module_name' is loaded."
      return 0
    fi
    sleep "$interval"
    echo "$elapsed"
    ((elapsed += interval))
  done

  echo "Timeout reached. Module '$module_name' not loaded."
  return 1
}

check_module_loaded casfs 60
if [[ $? -eq 0 ]]; then
  echo "Success: module loaded."
  abfs --remote-servers abfs-server:50051 --tunnel-ports 0 --manifest-server android.googlesource.com config -w
  abfs cacheman run -l /home/builder/.abfs/logs/cacheman
else
  echo "Failure: module not loaded in time."
  exit 1
fi
