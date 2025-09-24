// Copyright (c) 2025 Accenture, All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
folder('Android') {
  displayName('Android Workflows')
  description('<p>This folder contains pipelines and jobs related to environment administration, building, testing, and deploying Android applications.<br/>It includes workflows for administration, building and test tasks.</p>')
}
folder('Android/Builds') {
  displayName('Builds')
  description('<p>This folder contains jobs to build Android targets.</p>')
}
folder('Android/Environment') {
  displayName('Environment')
  description('''<p>This folder contains environment administrative jobs related to supporting Android workflows.</p>
    For AAOS, execute the following to ensure the environment is correctly provisioned:<br/>
    <ol><li><b>Docker Image Template:</b> create the Docker build container used for standard builds.</li>
    <li><b>CF Instance Template:</b> Create the Cuttlefish VM instance templates required for test jobs (dependent on Docker Image Template)</li>
    <li><b>ABFS:</b> If using ABFS then ensure those jobs in this folder are executed accordingly.</li></ol>''')
}
folder('Android/Environment/ABFS') {
  displayName('ABFS')
  description('''<p>This folder contains environment administrative jobs related to supporting Android Build File System (ABFS) workflows.</p>
    Ensure you execute in the following order to ensure ABFS environment is correctly provisioned before creating server and uploaders.<br/>
    <ol><li><b>Docker Image Template:</b> create the Docker build container used for ABFS builds.</li>
    <li><b>Docker Infra Image Template:</b> create the Docker infrastructure container for ABFS Server and Uploader jobs.</li></ol>
    <p>Once Docker templates have been created, refer to the <code>Server Administration</code> and <code>Uploader Administration</code> jobs to create and manage ABFS infrastructure.<br/>
    Refer to <i>docs/workloads/android/abfs.md</> for additional details.</p>''')
}
folder('Android/Environment/ABFS/Server Administration') {
  description('''<p>This folder contains ABFS server administrative jobs related to supporting Android Build File System (ABFS) workflows.</p>
    Ensure you create the server instance before creating the uploaders to avoid installation issues.<br/><br/>
    The other jobs here offer the ability to administer the spanner DB, especially useful when user destroys the ABFS server <br/>
    and thus ensuring all resources are released to reduce costs.<br/>
    <ol><li><b>Server Operations:</b> Create, destroy, stop, start the ABFS server</li>
    <li><b>Get Server Details:</b> Show server details such as current state.</li>
    <li><b>Get Spanner Details:</b> Show all server side details such as Spanner DB instance name, backup schedule and bucket storage.</li>
    <li><b>Update Spanner Backups:</b> Create, Delete or Update the Spanner DB backup schedule.</li>
    <li><b>Destroy Spanner Instance:</b> Create, Delete or Update the Spanner DB backup schedule.</li></ol>
    <p>Refer to <i>docs/workloads/android/abfs.md</> for additional details.</p>''')
}
folder('Android/Environment/ABFS/Uploader Administration') {
  description('''<p>This folder contains ABFS uploader administrative jobs related to supporting Android Build File System (ABFS) workflows.</p>
    Ensure you create the server instance before creating the uploaders to avoid installation issues.<br/>
    <ol><li><b>Uploader Operations:</b> Create, destroy, stop, start the ABFS uploaders,</li>
    <li><b>Get Uploader Details:</b> Show uploader details such as current state.</li></ol>
    <p>Refer to <i>docs/workloads/android/abfs.md</> for additional details.</p>''')
}
folder('Android/Tests') {
  displayName('Tests')
  description('<p>This folder contains jobs used to help test and validate Android builds.</p>')
}
