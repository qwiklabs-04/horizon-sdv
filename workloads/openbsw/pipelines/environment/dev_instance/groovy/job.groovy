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
pipelineJob('OpenBSW/Environment/Development Instance') {
  description("""
    <br/><h3 style="margin-bottom: 10px;">Development Build Instance Creation Job</h3>
    <p>This job allows creation of a temporary build instance that can be used to aid development and testing of builds.<br/>
    <h4 style="margin-bottom: 10px;">Instance Details</h4>
    <p>Instances can be expensive and therefore there is a maximum up-time before the instance will automatically be terminated.</p>
    <h4 style="margin-bottom: 10px;">Accessing the Instance</h4>
    <p>Access the instance via <code>bastion</code> host and <code>kubectl</code> command line tool. Example command:</p>
    <p><code>kubectl exec -it -n jenkins &lt;pod name&gt; -- bash</code></p>
    <h4 style="margin-bottom: 10px;">Important Notes</h4>
    <p>Users are responsible for saving their own work to persistent storage before expiry.</p>
    <br/><div style="border-top: 1px solid #ccc; width: 100%;"></div><br/>""")

  parameters {
    choiceParam {
      name('INSTANCE_MAX_UPTIME')
      choices(['0', '1', '2', '4', '8'])
      description('''<p>Time in hours to keep instance alive.</p>''')
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
      scriptPath('workloads/openbsw/pipelines/environment/dev_instance/Jenkinsfile')
    }
  }
}
