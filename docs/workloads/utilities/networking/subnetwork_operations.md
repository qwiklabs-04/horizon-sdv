# Subnetworking Operations

## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Environment Variables/Parameters](#environment-variables)
- [System Variables](#system-variables)

## Introduction <a name="introduction"></a>

This pipeline allows for users of Horizon-SDV create additional subnets and NAT/Cloud Routers, should
they need a second subnet for a secondary regions.

## Prerequisites<a name="prerequisites"></a>

Run the `Jenkins → Utilities → Docker Image Template` to create a container for kubernetes that will support this job.

## Environment Variables/Parameters <a name="environment-variables"></a>

**Jenkins Parameters:** Defined in the groovy job definition `groovy/job.groovy`.

### `ACTION`

Create, delete or provide details of the specified network.

Choice to create, delete or describe the subnet et al.
i.e. `DETAILS','CREATE','DELETE`


### `NETWORK`

The network to which the subnetwork belongs.

### `REGION`

Region for the subnet.

### `SUBNET`

If enabled, Subnet will be created/deleted.

### `SUBNET_NAME`

Subnet name.

### `RANGE`

The IP space allocated to this subnetwork in CIDR format.

### `SECONDARY_RANGE`

Adds a secondary IP range to the subnetwork for use in IP aliasing. PROPERTY=VALUE,...

### `STACK_TYPE`

The stack type for this subnet.

### `NAT_ROUTER`

If enabled, Compute Engine router and NAT will be create/deleted.

## SYSTEM VARIABLES <a name="system-variables"></a>

There are a number of system environment variables that are unique to each platform but required by Jenkins build, test and environment pipelines.

These are defined in Jenkins CasC `jenkins.yaml` and can be viewed in Jenkins UI under `Manage Jenkins` -> `System` -> `Global Properties` -> `Environment variables`.
These are as follows:

-   `UTILITIES_DOCKER_ARTIFACT_PATH_NAME`
    - Defines the registry path where the Docker image used to create the ABFS Server and Uploader VM instances.

-   `CLOUD_PROJECT`
    - The GCP project, unique to each project. Important for bucket, registry paths used in pipelines.

-   `CLOUD_REGION`
    - The GCP project region. Important for bucket, registry paths used in pipelines.

-   `HORIZON_GITHUB_URL`
    - The URL to the Horizon SDV GitHub repository.

-   `HORIZON_GITHUB_BRANCH`
    - The branch name the job will be configured for from `HORIZON_GITHUB_URL`.

-   `JENKINS_SERVICE_ACCOUNT`
    - Service account to use for pipelines. Required to ensure correct roles and permissions for GCP resources.
