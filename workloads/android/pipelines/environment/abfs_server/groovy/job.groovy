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
pipelineJob('Android/Environment/ABFS Server') {
  description("""
    <br/><h3 style="margin-bottom: 10px;">ABFS Server</h3>
    """)

  parameters {
    choiceParam {
      name('ABFS_TERRAFORM_ACTION')
      choices(['APPLY', 'DESTROY', 'START', 'STOP', 'RESTART'])
    }
    stringParam {
      name('SERVER_MACHINE_TYPE')
      defaultValue('n2-highmem-64')
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
      scriptPath('workloads/android/pipelines/environment/abfs_server/Jenkinsfile')
    }
  }
}
