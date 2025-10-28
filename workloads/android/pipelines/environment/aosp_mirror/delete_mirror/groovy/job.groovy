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
// This groovy job is used by the Seed Workloads Pipeline to define template and parameters for pipeline that executes delete-mirror operation of AOSP Mirror setup.
//
// References:
//

pipelineJob('Android/Environment/AOSP-Mirror/Delete Mirror') {
  description('''
    <br/><h3 style="margin-bottom: 10px;">Delete Existing AOSP Mirror</h3>

    <p><strong>WARNING</strong>: This action is IRREVERSIBLE and will permanently DELETE the specified mirror (or entire setup, if specified) for AOSP Mirror in your existing GCP project.</p>

    <p>It executes the following steps:</p>
    <ol>
      <li>
        <strong>If a specific mirror directory is provided via the <code>MIRROR_DIR_TO_DELETE</code> parameter:</strong> Deletes only that specified mirror directory and all its contents in the mirror storage volume.
      </li>
      <li>
        <strong>If the <code>DELETE_ENTIRE_MIRROR_SETUP</code> parameter is set to true:</strong> Deletes the entire AOSP Mirror setup (all mirrors), including the root mirror subdirectory, Filestore instance, and associated PV/PVC.
      </li>
    </ol>

    <h4 style="margin-bottom: 10px;">AOSP Mirror Setup to be deleted has the following properties:</h4>
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
      <li>If the specified mirror does not exist, this job fails.</li>
      <li>If you have set a periodic schedule for job `<i><code>AOSP Mirror > Sync Mirror</code></i>`, you will need to manually remove that schedule by editing that job configuration.</li>
    </ul>

    <br/><div style="border-top: 1px solid #ccc; width: 100%;"></div><br/>
  ''')

  logRotator {
    daysToKeep(60)
    numToKeep(200)
  }

  parameters {
    booleanParam('CONFIRM_DELETE', false, '<strong>REQUIRED:</strong> Check this box to confirm deletion. This action is irreversible.')
    booleanParam('DELETE_ENTIRE_MIRROR_SETUP', false, '''
      Optional: <strong>[CAUTION] If set to true, deletes the entire AOSP Mirror setup including the Filestore instance, associated Persistent Volume (PV) and Persistent Volume Claim (PVC).</strong><br>
      If set to false, only the specified mirror directory will be deleted from the Filestore instance, rest will remain intact.
    ''')
    stringParam('MIRROR_DIR_TO_DELETE', '', '''
      Optional: The specific mirror directory to delete.<br>
      Example: If you provided '<i><code>my-mirror</code></i>' when creating the mirror, provide the same value here to delete that specific mirror.<br>
      Note: When <code>DELETE_ENTIRE_MIRROR_SETUP</code> is set to true, this parameter is ignored and the entire setup is deleted.<br>
    ''')
    stringParam('IMAGE_TAG', 'latest', '''
      <strong>REQUIRED:</strong> The image tag for the Docker image to be used as environment for this job.<br>
      Note: Ensure you have executed that image build job prior to running this job, so that the required Docker image is available in your GCP project.
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
      scriptPath('workloads/android/pipelines/environment/aosp_mirror/delete_mirror/Jenkinsfile')
    }
  }
}