[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=draios_installer&metric=alert_status&token=ecba04faaa549f19a05480f249fcb0113cc43ef0)](https://sonarcloud.io/summary/new_code?id=draios_installer)

# Installer

The Sysdig Installer tool is a collection of scripts that help automate the
on-premises deployment of the Sysdig platform (Sysdig Monitor and Secure), for environments using Kubernetes or OpenShift. Use the Installer to
install or upgrade your Sysdig platform. It is recommended as a replacement
for the earlier manual install/upgrade procedures.

# Installation Overview

To install, you will log in to quay.io, download a sysdig-chart/values.yaml
file, provide a few basic parameters in it, and launch the Installer. In a
normal installation, the rest is automatically configured and deployed.

Note that you can perform a quick install if your environment has access to the
internet, or a partial or full airgapped installation, as needed. Each is
described below.

## Prerequisites

### Requirements for Installation Machine with Internet Access

- kubectl or oc binary
- Network access to quay.io
- A domain name you are in control of.

### Additional Requirements for Airgapped Environments

- Edited sysdig-chart/values.yaml, with airgap registry details updated
- Network and authenticated access to the private registry

### Access Requirements

- Sysdig license key (Monitor and/or Secure)
- Quay pull secret

# Quickstart Install

This install assumes the Kubernetes cluster has network access to pull images from quay.io.

- Copy the current version sysdig-chart/values.yaml to your working directory.
  ```bash
  wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/installer/installer/values.yaml
  ```
- Edit the following values:

  - [`size`](docs/02-configuration_parameters.md#size): Specifies the size of the cluster. Size
    defines CPU, Memory, Disk, and Replicas. Valid options are: small, medium and
    large.
  - [`quaypullsecret`](docs/02-configuration_parameters.md#quaypullsecret): quay.io provided with
    your Sysdig purchase confirmation mail.
  - [`storageClassProvisioner`](docs/02-configuration_parameters.md#storageClassProvisioner):
    The name of the storage class provisioner to use when creating the
    configured storageClassName parameter. If you do not use one of those two
    dynamic storage provisioners, then enter: hostPath and refer to the Advanced
    examples for how to configure static storage provisioning with this option.
    Valid options: aws, gke, hostPath
  - [`sysdig.license`](docs/02-configuration_parameters.md#sysdiglicense): Sysdig license key
    provided with your Sysdig purchase confirmation mail
  - [`sysdig.dnsName`](docs/02-configuration_parameters.md#sysdigdnsName): The domain name
    the Sysdig APIs will be served on.
  - [`sysdig.collector.dnsName`](docs/02-configuration_parameters.md#sysdigcollectordnsName):
    (OpenShift installs only) Domain name the Sysdig collector will be served on.
    When not configured it defaults to whatever is configured for sysdig.dnsName.
  - [`sysdig.ingressNetworking`](docs/02-configuration_parameters.md#sysdigingressnetworking):
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

      When not configured `sysdig.ingressNetworking` defaults to `hostnetwork`.

  **NOTE**: If doing an airgapped install (see Airgapped Installation Options), you
  would also edit the following values:

  - [`airgapped_registry_name`](docs/02-configuration_parameters.md#airgapped_registry_name):
    The URL of the airgapped (internal) docker registry. This URL is used for
    installations where the Kubernetes cluster can not pull images directly from
    Quay.
  - [`airgapped_repository_prefix`](docs/02-configuration_parameters.md#airgapped_repository_prefix):
    This defines custom repository prefix for airgapped_registry.
    Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag
  - [`airgapped_registry_password`](docs/02-configuration_parameters.md#airgapped_registry_password):
    The password for the configured airgapped_registry_username. Ignore this
    parameter if the registry does not require authentication.
  - [`airgapped_registry_username`](docs/02-configuration_parameters.md#airgapped_registry_username):
    The username for the configured airgapped_registry_name. Ignore this
    parameter if the registry does not require authentication.

- Download the installer binary that matches your OS from the
  [installer releases
  page](https://github.com/draios/installer/releases).
- Run the Installer.
  ```bash
  ./installer deploy
  ```
- On successful run of Installer towards the end of your terminal you should
  see the below:

  ```
  Congratulations, your Sysdig installation was successful!
  You can now login to the UI at "https://awesome-domain.com:443" with:

  username: "configured-username@awesome-domain.com"
  password: "awesome-password"

  Collector endpoint for connecting agents is: awesome-domain.com
  Collector port is: 6443
  ```

**NOTE**: Save the values.yaml file in a secure location; it will be used for
future upgrades. There will also be a generated directory containing various
Kubernetes configuration yaml files which were applied by Installer against
your cluster. It is not necessary to keep the generated directory, as the
Installer can regenerate is consistently with the same values.yaml file.

# Airgapped Installation Options

The Installer can be used to install in airgapped environments, either with
a multi-homed installation machine that has internet access, or in an
environment with no internet access.

## Airgapped with Multi-Homed Installation Machine

This assumes a private docker registry is used and the installation machine has
network access to pull from quay.io and push images to the private registry.

The Prerequisites and workflow are the same as in the Quickstart Install, with
the following exceptions:

- In step 2, add the airgap registry information.
- Make the installer push sysdig images to the airgapped registry by running:
```bash
./installer airgap
```
  That will pull all the images into `images_archive` directory as tar files
  and push them to the airgapped registry
- Run the Installer.
  ```bash
  ./installer deploy
  ```

## Full Airgap Install

This assumes a private docker registry is used and the installation machine
does not have network access to pull from quay.io, but can push images to the
private registry.

In this situation, a machine with network access (called the “jump machine”)
will pull an image containing a self-extracting tarball which can be copied to
the installation machine.

### Requirements for jump machine

- Network access to quay.io
- Docker
- jq

### Requirements for installation machine

- Network access to Kubernetes cluster
- Docker
- Network and authenticated access to the private registry
- Edited sysdig-chart/values.yaml, with airgap registry details updated

### Workflow

#### On the Jump Machine

- Follow the Docker Log In to quay.io steps under the Access Requirements section.
- Pull the image containing the self-extracting tar:
  ```bash
  docker pull quay.io/sysdig/installer:3.5.1-1-uber
  ```
- Extract the tarball:
  ```bash
  docker create --name uber_image quay.io/sysdig/installer:3.5.1-1-uber
  docker cp uber_image:/sysdig_installer.tar.gz .
  docker rm uber_image
  ```
- Copy the tarball to the installation machine.

#### On the Installation Machine:

- Copy the current version sysdig-chart/values.yaml to your working directory.
  ```bash
  wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/installer/installer/values.yaml
  ```
- Edit the following values:

  - [`size`](docs/02-configuration_parameters.md#size): Specifies the size of the cluster. Size
    defines CPU, Memory, Disk, and Replicas. Valid options are: small, medium and
    large
  - [`quaypullsecret`](docs/02-configuration_parameters.md#quaypullsecret): quay.io provided with
    your Sysdig purchase confirmation mail
  - [`storageClassProvider`](docs/02-configuration_parameters.md#storageClassProvider): The
    name of the storage class provisioner to use when creating the configured
    storageClassName parameter. Use hostPath or local in clusters that do not have
    a provisioner. For setups where Persistent Volumes and Persistent Volume Claims
    are created manually this should be configured as none. Valid options are:
    aws,gke,hostPath,local,none
  - [`sysdig.license`](docs/02-configuration_parameters.md#sysdiglicense): Sysdig license key
    provided with your Sysdig purchase confirmation mail
  - [`sysdig.dnsName`](docs/02-configuration_parameters.md#sysdigdnsName): The domain name
    the Sysdig APIs will be served on.
  - [`sysdig.collector.dnsName`](docs/02-configuration_parameters.md#sysdigcollectordnsName):
    (OpenShift installs only) Domain name the Sysdig collector will be served on.
    When not configured it defaults to whatever is configured for sysdig.dnsName.
  - [`sysdig.ingressNetworking`](docs/02-configuration_parameters.md#sysdigingressnetworking):
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
  - [`airgapped_registry_name`](docs/02-configuration_parameters.md#airgapped_registry_name):
    The URL of the airgapped (internal) docker registry. This URL is used for
    installations where the Kubernetes cluster can not pull images directly from
    Quay.
  - [`airgapped_repository_prefix`](docs/02-configuration_parameters.md#airgapped_repository_prefix):
      This defines custom repository prefix for airgapped_registry.
      Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag
  - [`airgapped_registry_password`](docs/02-configuration_parameters.md#airgapped_registry_password):
    The password for the configured airgapped_registry_username. Ignore this
    parameter if the registry does not require authentication.
  - [`airgapped_registry_username`](docs/02-configuration_parameters.md#airgapped_registry_username):
    The username for the configured airgapped_registry_name. Ignore this
    parameter if the registry does not require authentication.

- Copy the tarball file to the directory where you have your values.yaml file.
- Run:
```bash
installer airgap --tar-file sysdig_installer.tar.gz
```
The above step will extract the images into `images_archive` directory
relative to where the installer was run and push the images to the
airgapped_registry
- Run the Installer:
  ```bash
  ./installer deploy
  ```
- On successful run of Installer towards the end of your terminal you should
  see the below:

  ```
  All Pods Ready.....Continuing
  Congratulations, your Sysdig installation was successful!
  You can now login to the UI at "https://awesome-domain.com:443" with:

  username: "configured-username@awesome-domain.com"
  password: "awesome-password"
  ```

**NOTE**: Save the values.yaml file in a secure location; it will be used for
future upgrades. There will also be a generated directory containing various
Kubernetes configuration yaml files which were applied by Installer against
your cluster. It is not necessary to keep the generated directory, as the
Installer can regenerate is consistently with the same values.yaml file.

# Upgrades

See [upgrade.md](docs/03-upgrade.md) for upgrades documentation.

# Configuration Parameters and Examples

For the full dictionary of configuration parameters, see:
[configuration_parameters.md](docs/02-configuration_parameters.md)

# Permissions

## General
* CRU on the sysdig namespace
* CRU on StorageClass (only Read is required if the storageClass already exists)
* CRUD on Secrets/ServiceAccount/ConfigMap/Deployment/CronJob/Job/StatefulSet/Service/DaemonSet in the sysdig namespace.
* CRUD on role/rolebinding in sysdig namespace (if sysdig ingress controller is deployed)
* CRU on the ingress-controller(this is the name of the object) ClusterRole/ClusterRoleBinding (if sysdig ingress controller is deployed)
* Get Nodes (for validations).

## MultiAZ enabled
* CRU on the node-labels-to-files(this is the name of the object) ClusterRole/ClusterRoleBinding (for multi-AZ deployments)

## HostPath
* CRU on PV
* CRU on PVC in sysdig namespace

## Openshift
* CRUD on route in the sysdig namespace
* CRUD on openshift SCC in the sysdig namespace

## Network policies enabled
* CRUD on networkpolicies in sysdig namespace (if networkpolicies are enabled, this is an alpha feature customers should not enable it)


# Advanced Configuration

For advanced configuration option see [advanced.md](docs/04-advanced_configuration.md)

# Example values.yaml

- [single-node values.yaml](examples/single-node/values.yaml)
- [openshift-with-hostpath values.yaml](examples/openshift-with-hostpath/values.yaml)

# Resource requirements

The below table represents the amount of resources for various cluster sizes
in their default configuration. The `Redis HA` column indicates extra amount
of resources required if `redisHa: true` is configured.

| Application | SMALL        |            | GB              | GB            | GB      |     | MEDIUM       |            | GB              | GB            | GB      |     | LARGE |              | GB         | GB              | GB            |         |
| ----------- | ------------ | ---------- | --------------- | ------------- | ------- | --- | ------------ | ---------- | --------------- | ------------- | ------- | --- | ----- | ------------ | ---------- | --------------- | ------------- | ------- |
|             | cpu requests | cpu limits | memory requests | memory limits | storage |     | cpu requests | cpu limits | memory requests | memory limits | storage |     |       | cpu requests | cpu limits | memory requests | memory limits | storage |
| Platform    | 8.1          | 36         | 14.6            | 50            | 115     |     | 35.6         | 118        | 42.1            | 142           | 685     |     |       | 82.1         | 298        | 142.1           | 304           | 1885    |
| Monitor     | 5.6          | 18         | 10.1            | 30            | 85      |     | 30.6         | 98         | 37.1            | 122           | 625     |     |       | 76.1         | 278        | 136.1           | 280           | 1825    |
| Redis HA    | 0.45         | 6.9        | 0.345           | 6.06          |         |     | 0.45         | 6.9        | 0.345           | 6.06          |         |     |       | 0.45         | 6.9        | 0.345           | 6.06          |         |
