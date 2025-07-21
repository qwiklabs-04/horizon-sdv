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
  description('<p>This folder contains environment administrative jobs related to supporting Android workflows.</p>')
}
folder('Android/Environment/ABFS') {
  displayName('ABFS')
  description('<p>This folder contains environment administrative jobs related to supporting Android Build File System (ABFS) workflows.</p>')
}
folder('Android/Tests') {
  displayName('Tests')
  description('<p>This folder contains jobs used to help test and validate Android builds.</p>')
}
