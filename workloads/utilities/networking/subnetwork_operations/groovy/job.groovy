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
pipelineJob('Utilities/Networking/Subnetwork Operations') {
  description("""
    <br/><h3 style="margin-bottom: 10px;">Subnetwork Operations</h3>
    <p>This job allows creating a new subnetwork in the GCP project together with NAT router.</p>
    <h4 style="margin-bottom: 10px;">Prerequisites</h4>
    <p>Create the docker image template from <code>Utilities->Docker Image Template</code></p>
    <br/><div style="border-top: 1px solid #ccc; width: 100%;"></div><br/>""")

  parameters {

    separator {
      name('Subnetwork Parameters')
      sectionHeader('Subnetwork Operations')
      sectionHeaderStyle("${HEADER_STYLE}")
      separatorStyle("${SEPARATOR_STYLE}")
    }

    choiceParam {
      name('ACTION')
      choices(['DETAILS','CREATE','DELETE'])
      description('''<p>Create, delete or provide details of the specified network.</p>''')
    }

    stringParam {
      name('NETWORK')
      defaultValue('sdv-network')
      description('''<p>The network to which the subnetwork belongs.</p>''')
      trim(true)
    }

    stringParam {
      name('REGION')
      defaultValue("us-central1")
      description('''<p>Region for the subnet.</p>''')
      trim(true)
    }

    separator {
      name('Subnetwork Operations')
      sectionHeader('Subnetwork Operations')
      sectionHeaderStyle("${HEADER_STYLE}")
      separatorStyle("${SEPARATOR_STYLE}")
    }

    booleanParam {
      name('SUBNET')
      defaultValue(false)
      description('''<p>If enabled, Subnet will be created/deleted.</p>''')
    }

    stringParam {
      name('SUBNET_NAME')
      defaultValue("sdv-subnet-us")
      description('''<p>Subnet name.</p>''')
      trim(true)
    }

    stringParam {
      name('RANGE')
      defaultValue("10.2.0.0/24")
      description('''<p>The IP space allocated to this subnetwork in CIDR format.</p>''')
      trim(true)
    }

    stringParam {
      name('SECONDARY_RANGE')
      defaultValue("pods-range-us=10.20.0.0/16,services-range-us=10.22.0.0/16")
      description('''<p>Adds a secondary IP range to the subnetwork for use in IP aliasing. PROPERTY=VALUE,[…]</p>''')
      trim(true)
    }

    stringParam {
      name('STACK_TYPE')
      defaultValue("IPV4_ONLY")
      description('''<p>The stack type for this subnet</p>''')
      trim(true)
    }

    separator {
      name('Router Operations')
      sectionHeader('Router Operations')
      sectionHeaderStyle("${HEADER_STYLE}")
      separatorStyle("${SEPARATOR_STYLE}")
    }

    booleanParam {
      name('NAT_ROUTER')
      defaultValue(false)
      description('''<p>If enabled, Compute Engine router and NAT will be create/deleted.<br/>
      Default configuration will be created:
      <ul>
        <li><b>NATS:</b> <code>"${NETWORK}"-"${REGION}"-egress-nat</code>, e.g <code>sdv-network-us-central1-egress-nat</code></li>
        <li><b>Cloud Roter:</b> <code>"${NETWORK}"-"${REGION}"-nat-router</code>, e.g <code>sdv-network-us-central1-nat-router</code></li>
      </ul></p>''')
    }

  }

  // Block build if certain jobs are running.
  blockOn('Utilities*.*Subnet.*') {
    // Possible values are 'GLOBAL' and 'NODE' (default).
    blockLevel('GLOBAL')
    // Possible values are 'ALL', 'BUILDABLE' and 'DISABLED' (default).
    scanQueueFor('BUILDABLE')
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
      scriptPath('workloads/utilities/networking/subnetwork_operations/Jenkinsfile')
    }
  }
}

