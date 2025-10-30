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
// This groovy job is used by the Seed Workloads Pipeline to define template and parameters for pipeline that executes create_mirror operation of AOSP Mirror setup.
//
// References:
//

pipelineJob('Android/Environment/AOSP-Mirror/Create Mirror') {
  description('''
    <br/><h3 style="margin-bottom: 10px;">Create AOSP Mirror</h3>

    <p>This job provisions the resources for AOSP Mirror in your existing GCP project, and then triggers the downstream job `Sync Mirror` to download the AOSP source code.</p>

    <p>On the first run, it executes the following steps:</p>
    <ol>
      <li>Creates a Filestore instance in the same region this platform is running.</li>
      <li>Creates a Persistent Volume (PV) and Persistent Volume Claim (PVC) using the Filestore instance.</li>
      <li>Triggers the downstream job <strong><code>`AOSP Mirror > Sync Mirror`</code></strong> to perform the initial population of the mirror from official AOSP repository at <i><code>https://android.googlesource.com/mirror/manifest</code></i></li>
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
      <li>For a single GCP project, there can be <b>no more than one mirror</b> at any time.</li>
      <li>If the mirror already exists, executing this job will not create new resources but will just trigger the downstream job `Sync Mirror` to download or update the AOSP source code present on the mirror volume.</li>
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
    stringParam('MIRROR_MANIFEST_URL', 'https://android.googlesource.com/platform/manifest', '''
      <strong>REQUIRED:</strong> The URL of the manifest repository to be used for the AOSP Mirror.<br>
    ''')
    stringParam('MIRROR_MANIFEST_REF', 'android-16.0.0_r2', '''
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
      scriptPath('workloads/android/pipelines/environment/aosp_mirror/create_mirror/Jenkinsfile')
    }
  }
}
