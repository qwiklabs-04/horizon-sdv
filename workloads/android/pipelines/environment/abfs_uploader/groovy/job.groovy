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
pipelineJob('Android/Environment/ABFS Uploader') {
  description("""
    <br/><h3 style="margin-bottom: 10px;">Android Automotive Virtual Devices and Platform Targets Builder</h3>
    <p>This job is used to build Android Automotive virtual devices and platform targets from the provided source manifest.</p>
    <h4 style="margin-bottom: 10px;">Supported Builds</h4>
    <ul>
      <li><a href="https://source.android.com/docs/automotive/start/avd/android_virtual_device" target="_blank">Android Virtual Devices</a> for use with <a href="https://source.android.com/docs/automotive/start/avd/android_virtual_device#share-an-avd-image-with-android-studio-users" target="_blank">Android Studio</a></li> 
      <li><a href="https://source.android.com/docs/devices/cuttlefish" target="_blank">Cuttlefish Virtual Devices</a> for use with <a href="https://source.android.com/docs/compatibility/cts" target="_blank">CTS</a></li>
      <li>Reference hardware platforms such as <a href="https://github.com/raspberry-vanilla/android_local_manifest" target="_blank">RPi</a> and <a href="https://source.android.com/docs/automotive/start/pixelxl" target="_blank">Pixel Tablets</a></li>
    </ul>
    <h4 style="margin-bottom: 10px;">Build Outputs</h4>
    <p>Build outputs are stored in a Google Cloud Storage bucket (refer to build artifact for location).</p>
    <h4 style="margin-bottom: 10px;">Viewing Artifacts on Google Cloud</h4>
    <p><a href="https://cloud.google.com/docs/authentication/gcloud" target="_blank">Sign in to Google Cloud</a> and run the following command: <br/><code>gcloud storage ls gs://${ANDROID_BUILD_BUCKET_ROOT_NAME}/Android/Builds/AAOS_Builder/&lt;BUILD_NUMBER&gt;</code></p>
    <br/><div style="border-top: 1px solid #ccc; width: 100%;"></div><br/>""")

  parameters {
    choiceParam {
      name('INSTANCE_RETENTION_TIME')
      description('''<p>Time in minutes to retain the instance after build completion.<br/>
        Useful for debugging build issues, reviewing target outputs etc.</p>''')
      choices(['0', '15', '30', '45', '60', '120', '180'])
    }
    choiceParam {
      name('UPLOADER_APPLY_OR_DESTROY')
      choices(['APPLY', 'DESTROY'])
    }
    stringParam {
      name('UPLOADER_COUNT')
      defaultValue('1')
      trim(true)
    }
    stringParam {
      name('UPLOADER_MACHINE_TYPE')
      defaultValue('n2d-standard-4')
      trim(true)
    }
    stringParam {
      name('UPLOADER_DATADISK_SIZE_GB')
      defaultValue('1024')
      trim(true)
    }
    stringParam {
      name('UPLOADER_MANIFEST_SERVER')
      defaultValue('android.googlesource.com')
      trim(true)
    }
    stringParam {
      name('UPLOADER_GIT_BRANCH')
      defaultValue('["main"]')
      trim(true)
    }
    stringParam {
      name('UPLOADER_MANIFEST_FILE')
      defaultValue('default.xml')
      trim(true)
    }
  }

  logRotator {
    daysToKeep(60)
    numToKeep(200)
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
          branch("*/feature/wojciech.kobryn/TAA-824_Integrate_ABFS_terraform")
        }
      }
      scriptPath('workloads/android/pipelines/environment/abfs_uploader/Jenkinsfile')
    }
  }
}
