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
    <br/><h3 style="margin-bottom: 10px;">ABFS Uploader</h3>
    """)

  parameters {
    choiceParam {
      name('ABFS_TERRAFORM_ACTION')
      choices(['APPLY', 'DESTROY', 'START', 'STOP', 'RESTART'])
    }
    stringParam {
      name('UPLOADER_COUNT')
      defaultValue('1')
      trim(true)
    }
    stringParam {
      name('UPLOADER_MACHINE_TYPE')
      defaultValue('n2d-standard-48')
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
          branch("*/${HORIZON_GITHUB_BRANCH}")
        }
      }
      scriptPath('workloads/android/pipelines/environment/abfs_uploader/Jenkinsfile')
    }
  }
}
