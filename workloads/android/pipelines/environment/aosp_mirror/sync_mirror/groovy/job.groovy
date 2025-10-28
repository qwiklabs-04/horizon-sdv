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
// This groovy job is used by the Seed Workloads Pipeline to define template and parameters for pipeline that executes sync_mirror operation of AOSP Mirror setup.
//
// References:
//

pipelineJob('Android/Environment/AOSP-Mirror/Sync Mirror') {
  description('''
    <br/><h3 style="margin-bottom: 10px;">Sync AOSP Mirror</h3>

    <p>This job syncs the existing AOSP Mirror in your GCP project with the official AOSP repository at <i><code>https://android.googlesource.com/mirror/manifest</code></i></p>

    <h4 style="margin-bottom: 10px;">Periodic Sync</h4>
    <p>To keep the AOSP Mirror up-to-date with the official repository, you can set a schedule for this job to run periodically by following below steps:</p>
    <ol>
      <li>Click on the <strong><code>Configure</code></strong> option in the left-hand menu of this job.</li>
      <li>Scroll down to the <strong><code>Triggers</code></strong> section.</li>
      <li>Check the box for <strong><code>Build periodically</code></strong>.</li>
      <li>In the <strong><code>Schedule</code></strong> field, enter a cron expression that defines how often you want the job to run. For example, to run the job daily at midnight, you would enter: <i><code>H H * * *</code></i></li>
      <li>See the <a href="https://www.jenkins.io/doc/book/pipeline/syntax/#triggers">Jenkins cron syntax documentation</a> for more details.</li>
      <li>Click the <strong><code>Save</code></strong> button at the bottom of the page to apply your changes.</li>
    </ol>

    <h4 style="margin-bottom: 10px;">Preset Properties (Non-configurable):</h4>
    <ul>
      <li>DISK_NAME: <i><code>${AOSP_MIRROR_PRESET_FILESTORE_PVC_NAME}</code></i></li>
      <li>DISK_MOUNT_PATH_IN_CONTAINER: <i><code>${AOSP_MIRROR_PRESET_FILESTORE_PVC_MOUNT_PATH_IN_CONTAINER}</code></i></li>
      <li>MIRROR_ROOT_SUBDIRECTORY_IN_CONTAINER (All mirrors live inside this directory): <i><code>${AOSP_MIRROR_PRESET_FILESTORE_PVC_MOUNT_PATH_IN_CONTAINER}/${AOSP_MIRROR_PRESET_MIRROR_ROOT_SUBDIR_NAME}</code></i></li>
      <li>REGION: <i><code>${CLOUD_REGION}</code></i></li>
      <li>NETWORK: <i><code>${AOSP_MIRROR_PRESET_NETWORK_NAME}</code></i></li>
      <li>SUBNETWORK: <i><code>${AOSP_MIRROR_PRESET_SUBNETWORK_NAME}</code></i></li>
      <li>PROJECT: <i><code>${CLOUD_PROJECT}</code></i></li>
    </ul>

    <h4 style="margin-bottom: 10px;">Notes</h4>
    <ul>
      <li>If the mirror PVC `<i><code>${AOSP_MIRROR_PRESET_FILESTORE_PVC_NAME}</code></i>` does NOT exists, this job will fail. Run the 'AOSP Mirror > Create Mirror' pipeline prior to this job.</li>
    </ul>

    <br/><div style="border-top: 1px solid #ccc; width: 100%;"></div><br/>
  ''')

  logRotator {
    daysToKeep(60)
    numToKeep(200)
  }

  parameters {
    stringParam('IMAGE_TAG', 'latest', '''
      <strong>REQUIRED:</strong> The image tag for the Docker image to be used as environment for this job.<br>
      <b>Note:</b> Ensure you have executed that image build job prior to running this job, so that the required Docker image is available in your GCP project.
    ''')
    stringParam('MIRROR_DIR', '', '''
      <strong>REQUIRED:</strong> The directory name on the Filestore volume where the Mirror will be created.<br>
      <b>Example:</b> If you provide '<i><code>my-mirror</code></i>' as value, the mirror will be created at absolute container path '<i><code>${AOSP_MIRROR_PRESET_FILESTORE_PVC_MOUNT_PATH_IN_CONTAINER}/${AOSP_MIRROR_PRESET_MIRROR_ROOT_SUBDIR_NAME}/my-mirror</code></i>', where '<i><code>${AOSP_MIRROR_PRESET_MIRROR_ROOT_SUBDIR_NAME}</code>.</i>' is the root subdirectory for all mirrors.
    ''')
    stringParam('MIRROR_MANIFEST_URL', 'https://android.googlesource.com/mirror/manifest', '''
      <strong>REQUIRED:</strong> The URL of the manifest repository to be used for the AOSP Mirror.<br>
    ''')
    stringParam('MIRROR_MANIFEST_REF', 'refs/heads/main', '''
      <strong>REQUIRED:</strong> The manifest branch or tag to be used for the AOSP Mirror.<br>
    ''')
    stringParam('MIRROR_MANIFEST_FILE', 'default.xml', '''
      <strong>REQUIRED:</strong> The manifest file name to be used for the AOSP Mirror.<br>
    ''')
  }

  definition {
    cpsScm {
      lightweight()
      scm {
        git {
          remote {
            url("${HORIZON_GITHUB_URL}")
            credentials('jenkins-github-creds')
          }
          branch("*/${HORIZON_GITHUB_BRANCH}")
        }
      }
      scriptPath('workloads/android/pipelines/environment/aosp_mirror/sync_mirror/Jenkinsfile')
    }
  }
}