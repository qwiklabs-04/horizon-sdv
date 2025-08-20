// Copyright (c) 2024-2025 Accenture, All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Description:
// This groovy job is used by the Seed Workloads Pipeline to create folder structure for GCP Cloud Workstation pipelines
//
// References:
//

folder('Cloud-Workstations') {
  displayName('Cloud Workstations')
  description('<p>This folder contains jobs related to administration of GCP Cloud Workstations.</p>')
}

folder('Cloud-Workstations/Cluster-Admin-Operations') {
  displayName('Cluster Admin Operations')
  description('<p>This folder contains jobs that run operations on Clusters in GCP Cloud Workstations service as a Workstation Admin.</p>')
}

folder('Cloud-Workstations/Config-Admin-Operations') {
  displayName('Config Admin Operations')
  description('<p>This folder contains jobs that run operations on Configs in GCP Cloud Workstations service as a Workstation Admin.</p>')
}

folder('Cloud-Workstations/Workstation-Admin-Operations') {
  displayName('Workstation Admin Operations')
  description('<p>This folder contains jobs that run operations on Workstations in GCP Cloud Workstations service as a Workstation Admin.</p>')
}

folder('Cloud-Workstations/Workstation-User-Operations') {
  displayName('Workstation User Operations')
  description('<p>This folder contains jobs that run operations on Workstations in GCP Cloud Workstations service as a Workstation User.</p>')
}

folder('Cloud-Workstations/Environment') {
  displayName('Environment')
  description('<p>This folder contains a job that builds Docker image which will be used as environement for GCP Cloud Workstations pipeline jobs.</p>')
}

folder('Cloud-Workstations/Workstation-Images') {
  displayName('Workstation Images')
  description('<p>This folder contains a job that builds Docker image for the Code OSS (open-source VS Code) IDE for use in Cloud Workstations.</p>')
}
