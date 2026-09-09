# Installer

The Sysdig Installer tool is a golang binary that helps automate the on-premises deployment of the Sysdig platform (Sysdig Monitor and Sysdig Secure), for environments using Kubernetes or OpenShift. Use the Installer to install or upgrade your Sysdig platform. It is recommended as a replacement for the earlier manual installation and upgrade procedures.

# Installation Overview

To install you will:

1. Log in to quay.io
2. Download a sysdig-chart/values.yaml file
3. Provide a few basic parameters
4. Launch the Installer

In a successful installation, the Installer automatically completes the configuration and deployment.

If your environment has access to the internet, you can perform a quickstart install. If your environment is air-gapped, you can perform a partial or full installation, as needed. Each method is described below.

## Prerequisites

### Requirements for Environments with Internet Access

`kubectl` or `oc` binary at a version that matches the version on the target environment.
- Network access to quay.io
- A domain name you control

### Requirements for airgapped Environments

- Edited sysdig-chart/values.yaml, with air-gap registry details updated
- Network and authenticated access to the private registry

### Access Requirements

- Sysdig license key (Monitor and/or Secure)
- Quay pull secret

# Quickstart Install

Follow these steps if your cluster (Kubernetes or Openshift) has Internet access to pull images directly from `quay.io`:

1. Copy the current version of sysdig-chart/values.yaml to your working directory:

  ```bash
  wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/installer/installer/values.yaml
  ```
2. Edit the following values:

  - [`size`](docs/02-configuration_parameters.md#size): Specifies the size of the cluster. Size defines CPU, Memory, Disk, and Replicas. Valid options are: `small`, `medium` and `large`.
  - [`quaypullsecret`](docs/02-configuration_parameters.md#quaypullsecret): quay.io provided with your Sysdig purchase confirmation mail.
  - [`storageClassProvisioner`](docs/02-configuration_parameters.md#storageClassProvisioner): The name of the storage class provisioner to use when creating the configured storageClassName parameter. Valid options include: `aws`, `gke`, `hostPath`. If you do not use one of those dynamic storage provisioners, enter `hostPath` and refer to the Advanced examples for how to configure static storage provisioning with this option.
  - [`sysdig.license`](docs/02-configuration_parameters.md#sysdiglicense): Sysdig license key provided with your Sysdig purchase confirmation mail.
  - [`sysdig.platformAuditTrail.enabled`](docs/02-configuration_parameters.md#sysdigplatformAuditTrailenabled): To use Sysdig Platform Audit, set this parameter to `true`.
  - [`sysdig.secure.events.audit.config.store.ip`](docs/02-configuration_parameters.md#sysdigsecureeventsauditconfigstoreip): To see the origin IP address in Sysdig Platform Audit, set this parameter to `true`.
  - [`sysdig.dnsName`](docs/02-configuration_parameters.md#sysdigdnsName): The domain name the Sysdig APIs will be served on.
  - [`sysdig.collector.dnsName`](docs/02-configuration_parameters.md#sysdigcollectordnsName): (OpenShift installs only) Domain name the Sysdig collector will be served on. When not configured it defaults to whatever is configured for sysdig.dnsName.
  - [`sysdig.ingressNetworking`](docs/02-configuration_parameters.md#sysdigingressnetworking): The networking construct used to expose the Sysdig API and collector. The options are:

    - `hostnetwork`: sets the hostnetworking in the ingress daemonset and opens
      host ports for api and collector. This does not create a Kubernetes service.
    - `loadbalancer`: creates a service of type loadbalancer and expects that
      your Kubernetes cluster can provision a load balancer with your cloud provider.
    - `nodeport`: creates a service of type nodeport. The node ports can be
      customized with:

          - sysdig.ingressNetworkingInsecureApiNodePort
          - sysdig.ingressNetworkingApiNodePort
          - sysdig.ingressNetworkingCollectorNodePort

      When not configured `sysdig.ingressNetworking` defaults to `hostnetwork`.

  **NOTE**: For an airgapped install (see Airgapped Installation Options), also edit the following values:

  - [`airgapped_registry_name`](docs/02-configuration_parameters.md#airgapped_registry_name): The URL of the airgapped (internal) docker registry. This URL is used for installations where the Kubernetes cluster can not pull images directly from Quay.
  - [`airgapped_repository_prefix`](docs/02-configuration_parameters.md#airgapped_repository_prefix): This defines custom repository prefix for air-gapped_registry. Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag
  - [`airgapped_registry_password`](docs/02-configuration_parameters.md#airgapped_registry_password): The password for the configured airgapped_registry_username. Ignore this parameter if the registry does not require authentication.
  - [`airgapped_registry_username`](docs/02-configuration_parameters.md#airgapped_registry_username): The username for the configured airgapped_registry_name. Ignore this parameter if the registry does not require authentication.

3. Download the installer binary that matches your OS from the [installer releases page](https://github.com/draios/installer/releases).
4. Run the Installer.

  ```bash
  ./installer deploy
  ```
On successful run of Installer towards the end of your terminal you should see the below:

  ```
  Congratulations, your Sysdig installation was successful!
  You can now login to the UI at "https://awesome-domain.com:443" with:

  username: "configured-username@awesome-domain.com"
  password: "awesome-password"

  Collector endpoint for connecting agents is: awesome-domain.com
  Collector port is: 6443
  ```

5. Save the values.yaml file in a secure location; it will be used for future upgrades. 

The Installer also generates a directory containing all of the Kubernetes YAML manifests the Installer applied against your cluster. It is not necessary to keep this directory. The Installer can regenerate it by using the exact same binary, the exact same` values.yaml` and the `--skip-import` option.

# Airgapped Installation Options

The Installer can be used in airgapped environments, either with a multi-homed installation machine that has internet access, or in an environment with no internet access.

## Airgapped with Multi-Homed Installation Machine

This method uses a private docker registry. The installation machine requires network access to pull from quay.io and push images to the private registry.

The Prerequisites and workflow are the same as in the Quickstart Install, with the following exceptions:

- In step 2, add the air-gap registry information.
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

## Full Air-Gap Install

Use this method where the installation machine does not have network access to pull from quay.io, but can push images to a private docker registry. A machine with network access called the “jump machine” will pull an image containing a self-extracting tarball which can be copied to the installation machine.

### Requirements for Jump Machine

- Network access to quay.io
- Docker
- jq

### Requirements for Installation machine

- Network access to Kubernetes cluster
- Docker
- Network and authenticated access to the private registry
- Edited sysdig-chart/values.yaml, with air-gap registry details updated

### Workflow

#### On the Jump Machine

1. Follow the Docker Log In to quay.io steps under the Access Requirements section.
2. Pull the image containing the self-extracting tar:
  ```bash
  docker pull quay.io/sysdig/installer:3.5.1-1-uber
  ```
3. Extract the tarball:
  ```bash
  docker create --name uber_image quay.io/sysdig/installer:3.5.1-1-uber
  docker cp uber_image:/sysdig_installer.tar.gz .
  docker rm uber_image
  ```
4. Copy the tarball to the installation machine.

#### On the Installation Machine:

1. Copy the current version sysdig-chart/values.yaml to your working directory:
  ```bash
  wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/installer/installer/values.yaml
  ```
2. Edit the following values:

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

3. Copy the tarball file to the directory where you have your values.yaml file.
4. Run:
```bash
installer airgap --tar-file sysdig_installer.tar.gz
```
This extracts the images into the `images_archive` directory relative to where the installer was run and pushes the images to the airgapped_registry.

5. Run the Installer:
  ```bash
  ./installer deploy
  ```
  
On successful run of Installer towards the end of your terminal you should see this message:

  ```
  All Pods Ready.....Continuing
  Congratulations, your Sysdig installation was successful!
  You can now login to the UI at "https://awesome-domain.com:443" with:

  username: "configured-username@awesome-domain.com"
  password: "awesome-password"
  ```

6. Save the values.yaml file in a secure location; it will be used for future upgrades. 

There will also be a generated directory containing various Kubernetes configuration yaml files which were applied by Installer against your cluster. It is not necessary to keep the generated directory, as the Installer can regenerate is consistently with the same values.yaml file.

## Upgrades

See [upgrade.md](docs/03-upgrade.md) for upgrades documentation.

## Configuration Parameters and Examples

For the full dictionary of configuration parameters, see:
[configuration_parameters.md](docs/02-configuration_parameters.md)

## Permissions

### General
* CRU on the sysdig namespace
* CRU on StorageClass (only Read is required if the storageClass already exists)
* CRUD on Secrets/ServiceAccount/ConfigMap/Deployment/CronJob/Job/StatefulSet/Service/DaemonSet in the sysdig namespace.
* CRUD on role/rolebinding in sysdig namespace (if sysdig ingress controller is deployed)
* CRU on the ingress-controller(this is the name of the object) ClusterRole/ClusterRoleBinding (if sysdig ingress controller is deployed)
* Get Nodes (for validations).

### MultiAZ Enabled
* CRU on the node-labels-to-files(this is the name of the object) ClusterRole/ClusterRoleBinding (for multi-AZ deployments)

### HostPath
* CRU on PV
* CRU on PVC in sysdig namespace

### Openshift
* CRUD on route in the sysdig namespace
* CRUD on openshift SCC in the sysdig namespace

### Network Policies Enabled
* CRUD on networkpolicies in sysdig namespace (if networkpolicies are enabled, this is an alpha feature customers should not enable it)


## Advanced Configuration

For advanced configuration option see [advanced.md](docs/04-advanced_configuration.md)

## Example values.yaml

- [openshift-with-hostpath values.yaml](examples/openshift-with-hostpath/values.yaml)

## Resource Requirements

This table represents the amount of resources for various cluster sizes and deployment modes in their default configuration:

|Size                                    |Mode        |CPU Cores Requests|CPU Cores Limits|Memory GB Limits|Total Disk GB|
|----------------------------------------|------------|------------------|----------------|----------------|-------------|
|Small                                   |Secure Only |23                |80              |94              |947.15       |
|                                        |Platform    |53                |119             |213             |1403.15      |
|                                        |Monitor Only|26                |76              |169             |1191         |
|Medium                                  |Secure Only |37                |92              |109             |1589         |
|                                        |Platform    |61                |137             |222             |4244         |
|                                        |Monitor Only|31                |81              |182             |2616         |
|Large                                   |Secure Only |45                |101             |115             |3040         |
|                                        |Platform    |111               |166             |403             |10180        |
|                                        |Monitor Only|91                |120             |365             |6663         |
