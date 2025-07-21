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
pipelineJob('Android/Builds/AAOS ABFS Builder') {
  description("""
    <br/><h3 style="margin-bottom: 10px;">AAOS ABFS Builder</h3>
    """)

  parameters {
    stringParam {
      name('AAOS_REVISION')
      defaultValue('main')
      description('''<p>Android revision tag/branch name (main or android14-qpr1-release).</p>''')
      trim(true)
    }

    stringParam {
      name('ABFS_VERSION')
      defaultValue("${ABFS_VERSION}")
      description('''<p>ABFS version, e.g. 0.0.33-2-ge59ffbc, latest</p>''')
      trim(true)
    }

    stringParam {
      name('ABFS_REPOSITORY')
      defaultValue("${ABFS_REPOSITORY}")
      description('''<p>ABFS aptitude repository, e.g. abfs-apt-alpha-public. </p>''')
      trim(true)
    }

    stringParam {
      name('AAOS_LUNCH_TARGET')
      defaultValue('aosp_cf_x86_64_auto-trunk_staging-userdebug')
      description('''<p>Build Android cuttlefish (aosp_cf_x86_64_auto-trunk_staging-userdebug for main or aosp_cf_x86_64_auto-userdebug for Android QPR1).</p>''')
      trim(true)
    }

    stringParam {
      name('AAOS_SOONG_PATCH')
      defaultValue('92/3619492/1')
      description('''<p>Android SOONG patch for ABFS (92/3619492/1 for main or 08/3616708/1 for Android 14 QPR1).</p>''')
      trim(true)
    }

    choiceParam {
      name('INSTANCE_RETENTION_TIME')
      description('''<p>Time in minutes to retain the instance after build completion.<br/>
        Useful for debugging build issues, reviewing target outputs etc.</p>''')
      choices(['0', '15', '30', '45', '60', '120', '180'])
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
      scriptPath('workloads/android/pipelines/builds/aaos_abfs_builder/Jenkinsfile')
    }
  }
}
