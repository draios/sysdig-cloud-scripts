# Installer

The Sysdig Installer tool is a collection of scripts that help automate the
on-premises deployment of the Sysdig platform (Sysdig Monitor, Secure and Agent), for environments using Kubernetes or OpenShift. Use the Installer to install or upgrade your Sysdig platform. It is recommended as a replacement
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

- Network access to Kubernetes cluster
- Docker
- Bash
- jq
- Network access to quay.io
- A domain name you are in control of.

### Additional Requirements for Airgapped Environments

- Edited sysdig-chart/values.yaml, with airgap registry details updated
- Network and authenticated access to the private registry

### Access Requirements

- Sysdig license key (Monitor and/or Secure)
- Quay pull secret
- Anchore license file (if Secure is licensed)
- Docker Log In to quay.io
- Retrieve Quay username and password from Quay pull secret.
  For example:
  ```bash
  AUTH=$(echo <REPLACE_WITH_quaypullsecret> | base64 --decode | jq -r '.auths."quay.io".auth'| base64 --decode)
  QUAY_USERNAME=${AUTH%:*}
  QUAY_PASSWORD=${AUTH#*:}
  ```
- Log in to quay.io using the username and password retrieved above.
  ```bash
  docker login -u "$QUAY_USERNAME" -p "$QUAY_PASSWORD" quay.io
  ```

# Quickstart Install

This install assumes the Kubernetes cluster has network access to pull images from quay.io.

- Copy the current version sysdig-chart/values.yaml to your working directory.
  ```bash
  wget https://raw.githubusercontent.com/draios/sysdigcloud-kubernetes/installer/installer/values.yaml
  ```
- Edit the following values:

  - [`size`](docs/configuration_parameters.md#size): Specifies the size of the cluster. Size
    defines CPU, Memory, Disk, and Replicas. Valid options are: small, medium and
    large.
  - [`quaypullsecret`](docs/configuration_parameters.md#quaypullsecret): quay.io provided with
    your Sysdig purchase confirmation mail.
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

      When not configured `sysdig.ingressNetworking` defaults to `hostnetwork`.

  **NOTE**: If doing an airgapped install (see Airgapped Installation Options), you
  would also edit the following values:

  - [`airgapped_registry_name`](docs/configuration_parameters.md#airgapped_registry_name):
    The URL of the airgapped (internal) docker registry. This URL is used for
    installations where the Kubernetes cluster can not pull images directly from
    Quay.
  - [`airgapped_repository_prefix`](docs/configuration_parameters.md#airgapped_repository_prefix):
    This defines custom repository prefix for airgapped_registry.
    Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag
  - [`airgapped_registry_password`](docs/configuration_parameters.md#airgapped_registry_password):
    The password for the configured airgapped_registry_username. Ignore this
    parameter if the registry does not require authentication.
  - [`airgapped_registry_username`](docs/configuration_parameters.md#airgapped_registry_username):
    The username for the configured airgapped_registry_name. Ignore this
    parameter if the registry does not require authentication.

- Run the Installer. (Note: This step differs in [Airgapped Installation
  Options](#airgapped-installation-options).)
  ```bash
  docker run \
    -e HOST_USER=$(id -u) \
    -e KUBECONFIG=/.kube/config \
    -v ~/.kube:/.kube:Z \
    -v $(pwd):/manifests:Z \
    quay.io/sysdig/installer:3.2.2-1
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

# Agent Install

The sysdig agent can be installed along with Sysdig Monitor and/or Sysdig Secure or just by itself. This is determined by the value `apps` in `values.yaml` file.

This section assumes you will run the agent container as a Kubernetes pod, which then enables the Sysdig agent automatically to detect and monitor your Kubernetes environment. For setting up Sysdig Agent, you will need the api key for agent from you Sysdig Monitor. Instructions for retrieving the api key can be found [here](https://docs.sysdig.com/en/agent-installation--overview-and-key.html).

In case, you are setting up both Monitor and Agent together, you can provide a blank value for the `agent.apiKey`. The agent will be launched with the appropriate api key and the value updated in the `values.yaml` file.

- Copy the current version sysdig-chart/values.yaml to your working directory.

  ```bash
  wget https://raw.githubusercontent.com/draios/sysdigcloud-kubernetes/installer/installer/values.yaml
  ```

- The following values are necessary for setting up Sysdig Agent. Edit the values.yaml to contain the following values:

  - [`apps`](docs/configuration_parameters.md#apps): Specifies the Sysdig Platform components to be installed. Make sure `agent` is one of the values here.
  - [`size`](docs/configuration_parameters.md#size): Specifies the size of the cluster. Size
    defines CPU and Memory limits for the Agent Pods. Valid options are: small, medium and
    large.
  - [`agent.apiKey`](docs/configuration_parameters.md#agentapikey): Sysdig Agent api key for running agents.
  - [`agent.collectorEndpoint`](docs/configuration_parameters.md#agentcollectorendpoint): Sysdig Collector Address

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

- In step 3, run the Installer as follows:

```bash
docker run \
  -e HOST_USER=$(id -u) \
  -e KUBECONFIG=/.kube/config \
  -v ~/.kube:/.kube:Z \
  -v $(pwd):/manifests:Z \
  -v /var/run/docker.sock:/var/run/docker.sock:Z \
  -v ~/.docker:/root/docker:Z \
  quay.io/sysdig/installer:3.2.2-1
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
- Bash
- tar
- Network and authenticated access to the private registry
- Edited sysdig-chart/values.yaml, with airgap registry details updated

### Workflow

#### On the Jump Machine

- Follow the Docker Log In to quay.io steps under the Access Requirements section.
- Pull the image containing the self-extracting tar:
  ```bash
  docker pull quay.io/sysdig/installer:3.2.2-1-uber
  ```
- Extract the tarball:
  ```bash
  docker create --name uber_image quay.io/sysdig/installer:3.2.2-1-uber
  docker cp uber_image:/sysdig_installer.tar.gz .
  docker rm uber_image
  ```
- Copy the tarball to the installation machine.

#### On the Installation Machine:

- Copy the current version sysdig-chart/values.yaml to your working directory.
  ```bash
  wget https://raw.githubusercontent.com/draios/sysdigcloud-kubernetes/installer/installer/values.yaml
  ```
- Edit the following values:

  - [`size`](docs/configuration_parameters.md#size): Specifies the size of the cluster. Size
    defines CPU, Memory, Disk, and Replicas. Valid options are: small, medium and
    large
  - [`quaypullsecret`](docs/configuration_parameters.md#quaypullsecret): quay.io provided with
    your Sysdig purchase confirmation mail
  - [`storageClassProvider`](docs/configuration_parameters.md#storageClassProvider): The
    name of the storage class provisioner to use when creating the configured
    storageClassName parameter. Use hostPath or local in clusters that do not have
    a provisioner. For setups where Persistent Volumes and Persistent Volume Claims
    are created manually this should be configured as none. Valid options are:
    aws,gke,hostPath,local,none
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
  - [`airgapped_registry_name`](docs/configuration_parameters.md#airgapped_registry_name):
    The URL of the airgapped (internal) docker registry. This URL is used for
    installations where the Kubernetes cluster can not pull images directly from
    Quay.
  - [`airgapped_repository_prefix`](docs/configuration_parameters.md#airgapped_repository_prefix):
      This defines custom repository prefix for airgapped_registry.
      Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag
  - [`airgapped_registry_password`](docs/configuration_parameters.md#airgapped_registry_password):
    The password for the configured airgapped_registry_username. Ignore this
    parameter if the registry does not require authentication.
  - [`airgapped_registry_username`](docs/configuration_parameters.md#airgapped_registry_username):
    The username for the configured airgapped_registry_name. Ignore this
    parameter if the registry does not require authentication.

- Copy the tarball file to the directory where you have your values.yaml file.
- Run the tar file:
  `bash sysdig_installer.tar.gz`
- The above step extracts images, runs installer and pushes images to the remote repository in one step. The extract, push images can be redundant for successive installer runs. Setting IMAGE_EXTRACT_PUSH=false runs only the installer.
  `IMAGE_EXTRACT_PUSH=false bash sysdig_installer.tar.gz`
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

See [upgrade.md](docs/upgrade.md) for upgrades documentation.

# Configuration Parameters and Examples

For the full dictionary of configuration parameters, see:
[configuration_parameters.md](docs/configuration_parameters.md)

# Advanced Configuration

For advanced configuration option see [advanced.md](docs/advanced.md)

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
| Agent       | 1            | 3          | 1               | 3             |         |     | 3            | 5          | 3               | 6             |         |     |       | 5            | 8          | 6               | 10            |         |
