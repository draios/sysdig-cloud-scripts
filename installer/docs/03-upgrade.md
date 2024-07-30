<!-- Space: IONP -->
<!-- Parent: Installer -->
<!-- Parent: Git Synced Docs -->
<!-- Title: Upgrade -->
<!-- Layout: plain -->

# Upgrade

<br />

<!-- Include: ac:toc -->

<br />

## Overview

The Installer can be used to upgrade a Sysdig implementation. As in an
install, you must meet the prerequisites, download the values.yaml, edit the
values as indicated, and run the Installer. The main difference is that you
run it twice: once to discover the differences between the old and new
versions, and the second time to deploy the new version.

As with installs, it can be used in airgapped or non-airgapped environments.

Review the [Prerequisites](../README.md#prerequisites) and [Installation
Options](../README.md#quickstart-install) for more context.

## Upgrade Steps

<br />

### Step 1 - Download the latest `values.yaml` template

Copy the current version `sysdig-chart/values.yaml` to your working directory.

```bash
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/installer/installer/values.yaml
```

<br />

### Step 2 - Configure `values.yaml` according to your environment

Edit the following values:

- [`scripts`](docs/configuration_parameters.md#scripts): Set this to
  `generate diff`. This setting will generate the differences between the
  installed environment and the upgrade version. The changes will be displayed
  in your terminal.
- [`size`](docs/configuration_parameters.md#size): Specifies the size of the
  cluster. Size defines CPU, Memory, Disk, and Replicas. Valid options are:
  small, medium and large.
- [`quaypullsecret`](docs/configuration_parameters.md#quaypullsecret):
  quay.io credentials provided with your Sysdig purchase confirmation mail.
- [`storageClassProvisioner`](docs/configuration_parameters.md#storageClassProvisioner):
  The name of the storage class provisioner to use when creating the
  configured storageClassName parameter. If you do not use one of those two
  dynamic storage provisioners, then enter: hostPath and refer to the Advanced
  examples for how to configure static storage provisioning with this option.
  Valid options: aws, gke, hostPath
- [`sysdig.license`](docs/configuration_parameters.md#sysdiglicense): Sysdig license key
  provided with your Sysdig purchase confirmation mail
- [`sysdig.dnsName`](docs/configuration_parameters.md#sysdigdnsName): The domain name
  the Sysdig APIs will be served on.
- [`sysdig.collector.dnsName`](docs/configuration_parameters.md#sysdigcollectordnsName):
  (OpenShift installs only) Domain name the Sysdig collector will be served on.
  When not configured it defaults to whatever is configured for sysdig.dnsName.
- [`sysdig.ingressNetworking`](docs/configuration_parameters.md#sysdigingressnetworking):
  The networking construct used to expose the Sysdig API and collector. Options
  are:

  - hostnetwork: sets the hostnetworking in the ingress daemonset and opens
    host ports for api and collector. This does not create a Kubernetes service.
  - loadbalancer: creates a service of type loadbalancer and expects that
    your Kubernetes cluster can provision a load balancer with your cloud provider.
  - nodeport: creates a service of type nodeport. The node ports can be
    customized with:

    - sysdig.ingressNetworkingInsecureApiNodePort
    - sysdig.ingressNetworkingApiNodePort
    - sysdig.ingressNetworkingCollectorNodePort

**NOTE**: If doing an airgapped install (see Airgapped Installation Options), you
would also edit the following values:

- [`airgapped_registry_name`](docs/configuration_parameters.md#airgapped_registry_name):
  The URL of the airgapped (internal) docker registry. This URL is used for
  installations where the Kubernetes cluster can not pull images directly from
  Quay.
- [`airgapped_registry_password`](docs/configuration_parameters.md#airgapped_registry_password):
  The password for the configured airgapped_registry_username. Ignore this
  parameter if the registry does not require authentication.
- [`airgapped_registry_username`](docs/configuration_parameters.md#airgapped_registry_username):
  The username for the configured airgapped_registry_name. Ignore this
  parameter if the registry does not require authentication.

<br />

### Step 3 - Check differences with the old Sysdig environment

Run the Installer (if you are in airgapped environment make sure you follow
instructions from installation on how to get the images to your airgapped
registry)

```bash
./installer diff
```

<br />

### Step 4 - Deploy Sysdig version

If you are fine with the differences displayed, then run:

```bash
./installer deploy
```

If you find differences that you want to preserve you should
look in the [Configuration Parameters](docs/configuration_parameters.md)
documentation for the configuration parameter that matches the difference
you intend preserving and update your values.yaml accordingly then repeat
step 3 until you are fine with the differences. Then set scripts to deploy
and run for the final time.

<br />
