# Configuration Parameters

## **quaypullsecret**
**Required**: `true`<br>
**Description**: quay.io credentials provided with your Sysdig purchase confirmation
  mail.<br>
**Options**:<br>
**Default**: <br>
**Example**:

```yaml
quaypullsecret: Y29tZS13b3JrLWF0LXN5c2RpZwo=
```

## **schema_version**
**Required**: `true`<br>
**Description**: Represents the schema version of the values.yaml
configuration. Versioning follows [Semver](https://semver.org/) (Semantic
Versioning) and maintains semver guarantees about versioning.<br>
**Options**:<br>
**Default**: `1.0.0`<br>
**Example**:

```yaml
schema_version: 1.0.0
```

## **size**
**Required**: `true`<br>
**Description**: Specifies the size of the cluster. Size defines CPU, Memory,
Disk, and Replicas.<br>
**Options**: `small|medium|large`<br>
**Default**:<br>
**Example**:

```yaml
size: medium
```

## **storageClassProvisioner**
**Required**: `true`<br>
**Description**: The name of the [storage class
provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner)
to use when creating the configured storageClassName parameter. Use hostPath
or local in clusters that do not have a provisioner. For setups where
Persistent Volumes and Persistent Volume Claims are created manually this
should be configured as `none`.<br>
**Options**: `aws|gke|hostPath|local|none`<br>
**Default**:<br>
**Example**:

```yaml
storageClassProvisioner: aws
```

## **apps**
**Required**: `false`<br>
**Description**: Specifies the Sysdig Platform components to be installed.<br>
Combine multiple components by space separating them. Specify at least one
app, for example, `monitor`.<br>
**Options**: `monitor|monitor secure`<br>
**Default**: `monitor secure`<br>
**Example**:

```yaml
apps: monitor secure
```

## **airgapped_registry_name**
**Required**: `false`<br>
**Description**: The URL of the airgapped (internal) docker registry. This URL
is used for installations where the Kubernetes cluster can not pull images
directly from Quay. See [airgap instructions
multi-homed](usage.md#airgap-installation-with-installation-machine-multi-homed)
and [full airgap instructions](../usage.md#full-airgap-installation) for more
details.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
airgapped_registry_name: my-awesome-domain.docker.io
```

## **airgapped_registry_password**
**Required**: `false`
**Description**: The password for the configured
`airgapped_registry_username`. Ignore this parameter if the registry does not
require authentication.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
airgapped_registry_password: my-@w350m3-p@55w0rd
```

## **airgapped_registry_username**
**Required**: `false`<br>
**Description**: The username for the configured `airgapped_registry_name`.
Ignore this parameter if the registry does not require authentication.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
airgapped_registry_username: bob+alice
```

## **deployment**
**Required**: `false`<br>
**Description**: The name of the Kubernetes installation.<br>
**Options**: `iks|kubernetes|openshift`<br>
**Default**: `kubernetes`<br>
**Example**:

```yaml
deployment: kubernetes
```

## **localStoragehostDir**
**Required**: `false`<br>
**Description**: The path on the host where the local volumes are mounted
under. This  is relevant only when `storageClassProvisioner` is `local`.<br>
**Options**:<br>
**Default**: `/sysdig`<br>
**Example**:

```yaml
localStoragehostDir: /sysdig
```

## **namespace**
**Required**: `false`<br>
**Description**: Kubernetes namespace to deploy Sysdig Platform to.<br>
**Options**:<br>
**Default**: `sysdig`<br>
**Example**:

```yaml
namespace: sysdig
```

## **scripts**
**Required**: `false`<br>
**Description**: Defines which scripts needs to be run.<br>
  `generate`: performs templating and customization.<br>
  `diff`: generates diff against in-cluster configuration.<br>
  `deploy`: applies the generated script in Kubernetes environment.<br>
These options can be combined by space separating them.<br>
**Options**: `generate|diff|deploy|generate diff|generate deploy|diff deploy|generate diff deploy`<br>
**Default**: `generate deploy`<br>
**Example**:

```yaml
scripts: generate diff
```

## **storageClassName**
**Required**: `false`<br>
**Description**: The name of the preconfigured [storage
class](https://kubernetes.io/docs/concepts/storage/storage-classes/). If the
storage class does not exist, Installer will attempt to create it using the
`storageClassProvisioner` as the provisioner. This has no effect if
`storageClassProvisioner` is configured to `none`.<br>
**Options**:<br>
**Default**: `sysdig`<br>
**Example**:

```yaml
storageClassName: sysdig
```

## ~~**cloudProvider.create_loadbalancer**~~ (**Deprecated**)
**Required**: `false`<br>
**Description**: This is deprecated, prefer
[`sysdig.ingressNetworking`](#sysdigingressnetworking) instead. When set to
true a service of type
[LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)
is created.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
cloudProvider:
  create_loadbalancer: true
```

## **cloudProvider.isMultiAZ**
**Required**: `false`<br>
**Description**: Specifies whether the underlying Kubernetes cluster is
deployed in multiple availability zones. The parameter requires
[`cloudProvider.name`](#cloudprovidername) to be configured. <br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
cloudProvider:
  isMultiAZ: false
```

## **cloudProvider.name**
**Required**: `false`<br>
**Description**: The name of the cloud provider Sysdig Platform will run on.<br>
**Options**: `aws|gke`<br>
**Default**:<br>
**Example**:

```yaml
cloudProvider:
  name: aws
```

## **cloudProvider.region**
**Required**: `false`<br>
**Description**: The cloud provider region the underlying Kubernetes Cluster
runs on. This parameter is required if
[`cloudProvider.name`](#cloudprovidername) is configured.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
cloudProvider:
  region: us-east-1
```

## **elasticsearch.hostPathNodes**
**Required**: `false`<br>
**Description**: An array of node hostnames printed out by the `kubectl get
node -o name` command. ElasticSearch hostPath persistent volumes should be
created on these nodes. The number of nodes must be at minimum whatever the
value of
[`sysdig.elasticsearchReplicaCount`](#sysdigelasticsearchreplicacount) is.
This is required if configured
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: [] <br>

**Example**:

```yaml
elasticsearch:
  hostPathNodes:
    - my-cool-host1.com
    - my-cool-host2.com
    - my-cool-host3.com
    - my-cool-host4.com
    - my-cool-host5.com
    - my-cool-host6.com
```


## **elasticsearch.jvmOptions**
**Required**: `false`<br>
**Description**: Custom configuration for Elasticsearch JVM.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
elasticsearch:
  jvmOptions: -Xms4G -Xmx4G
```

## **elasticsearch.external**
**Required**: `false`<br>
**Description**: If set does not create a local Elasticsearch cluster, tries connecting to an external Elasticsearch cluster.
This can be used in conjunction with [`elasticsearch.hostname`](#elasticsearchhostname) <br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
elasticsearch:
  external: true
```

## **elasticsearch.hostname**
**Required**: `false`<br>
**Description**:  External Elasticsearch hostname can be provided here and certificates for clients can be provided under certs/elasticsearch-tls-certs.<br>
**Options**: <br>
**Default**: 'sysdigcloud-elasticsearch'<br>
**Example**:

```yaml
elasticsearch:
  external: true
  hostname: external.elasticsearch.cluster
```

## ~~**elasticsearch.searchguard.enabled**~~ (**Deprecated**)
**Required**: `false`<br>
**Description**: Enables user authentication and TLS-encrypted data-in-transit
with [Searchguard](https://search-guard.com/)
If Searchguard is enabled Installer does the following in the provided order:
  1. Checks for user provided certificates under certs/elasticsearch-tls-certs if present uses that to setup elasticsearch(es) cluster.
  2. Checks for existing searchguard certificates in the provided environment to setup ES cluster. (applicable for upgrades)
  3. If neither of them are present Installer autogenerates searchguard certificates and uses them to setup es cluster.


**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
elasticsearch:
  searchguard:
    enabled: false
```

## ~~**elasticsearch.searchguard.adminUser**~~ (**Deprecated**)
**Required**: `false`<br>
**Description**: The user bound to the ElasticSearch Searchguard admin role.<br>
**Options**: <br>
**Default**: `sysdig`<br>
**Example**:

```yaml
elasticsearch:
  searchguard:
    adminUser: admin
```

## **elasticsearch.snitch.extractCMD**
**Required**: `false`<br>
**Description**: The command used to determine [elasticsearch cluster routing
allocation awareness
attributes](https://www.elastic.co/guide/en/elasticsearch/reference/current/allocation-awareness.html).
The command will be passed to the bash eval command and is expected to return
a single string. For example: `cut -d- -f2 /host/etc/hostname`.<br>
**Options**: <br>
**Default**: `sysdig`<br>
**Example**:

```yaml
elasticsearch:
  snitch:
    extractCMD: cut -d- -f2 /host/etc/hostname
```

## **elasticsearch.snitch.hostnameFile**
**Required**: `false`<br>
**Description**: The name of the location to bind mount the host's
`/etc/hostname` file to. This can be combined with
[`elasticsearch.snitch.extractCMD`](#elasticsearchsnitchextractcmd) to
determine cluster routing allocation associated with the node's hostname.<br>
**Options**: <br>
**Default**: `sysdig`<br>
**Example**:

```yaml
elasticsearch:
  snitch:
    hostnameFile: /host/etc/hostname
```

## **hostPathCustomPaths.cassandra**
**Required**: `false`<br>
**Description**: The directory to bind mount Cassandra pod's
`/var/lib/cassandra` to on the host. This parameter is relevant only when
`storageClassProvisioner` is `hostPath`. <br>
**Options**: <br>
**Default**: `/var/lib/cassandra`<br>
**Example**:

```yaml
hostPathCustomPaths:
  cassandra: `/sysdig/cassandra`
```

## **hostPathCustomPaths.elasticsearch**
**Required**: `false`<br>
**Description**: The directory to bind mount elasticsearch pod's
`/usr/share/elasticsearch` to on the host. This parameter is relevant only when
`storageClassProvisioner` is `hostPath`.<br>
**Options**: <br>
**Default**: `/usr/share/elasticsearch`<br>
**Example**:

```yaml
hostPathCustomPaths:
  elasticsearch: `/sysdig/elasticsearch`
```

## **hostPathCustomPaths.mysql**
**Required**: `false`<br>
**Description**: The directory to bind mount mysql pod's `/var/lib/mysql` to
on the host. This is relevant only when `storageClassProvisioner` is
`hostPath`.<br>
**Options**:<br>
**Default**: `/var/lib/mysql`<br>
**Example**:

```yaml
hostPathCustomPaths:
  mysql: `/sysdig/mysql`
```

## **hostPathCustomPaths.postgresql**
**Required**: `false`<br>
**Description**: The directory to bind mount PostgreSQL pod's
`/var/lib/postgresql/data/pgdata` to on the host. This parameter is relevant
only when `storageClassProvisioner` is `hostPath`.<br>
**Options**: <br>
**Default**: `/var/lib/postgresql/data/pgdata`<br>
**Example**:

```yaml
hostPathCustomPaths:
  postgresql: `/sysdig/pgdata`
```

## **nodeaffinityLabel.key**
**Required**: `false`<br>
**Description**: The key of the label that is used to configure the nodes that the
Sysdig Platform pods are expected to run on. The nodes are expected to have
been labeled with the key.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
nodeaffinityLabel:
  key: instancegroup
```

## **nodeaffinityLabel.value**
**Required**: `false`<br>
**Description**: The value of the label that is used to configure the nodes
that the Sysdig Platform pods are expected to run on. The nodes are expected
to have been labeled with the value of
[`nodeaffinityLabel.key`](#nodeaffinitylabelkey), and is required if
[`nodeaffinityLabel.key`](#nodeaffinitylabelkey) is configured.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
nodeaffinityLabel:
  value: sysdig
```

## **pvStorageSize.large.cassandra**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Cassandra in a
cluster of [`size`](#size) large. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 300Gi<br>
**Example**:

```yaml
pvStorageSize:
  large:
    cassandra: 500Gi
```

## **pvStorageSize.large.elasticsearch**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Elasticsearch
in a cluster of [`size`](#size) large. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 300Gi<br>
**Example**:

```yaml
pvStorageSize:
  large:
    elasticsearch: 500Gi
```

## **pvStorageSize.large.mysql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to MySQL in a
cluster of [`size`](#size) large. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 25Gi<br>
**Example**:

```yaml
pvStorageSize:
  large:
    mysql: 100Gi
```

## **pvStorageSize.large.postgresql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to PostgreSQL in a
cluster of [`size`](#size) large. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 60Gi<br>
**Example**:

```yaml
pvStorageSize:
  large:
    postgresql: 100Gi
```

## **pvStorageSize.medium.cassandra**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Cassandra in a
cluster of [`size`](#size) medium. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 100Gi<br>
**Example**:

```yaml
pvStorageSize:
  medium:
    cassandra: 300Gi
```

## **pvStorageSize.medium.elasticsearch**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Elasticsearch in a
cluster of [`size`](#size) medium. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 100Gi<br>
**Example**:

```yaml
pvStorageSize:
  medium:
    elasticsearch: 300Gi
```

## **pvStorageSize.medium.mysql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to MySQL in a
cluster of [`size`](#size) medium. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 25Gi<br>
**Example**:

```yaml
pvStorageSize:
  medium:
    mysql: 100Gi
```

## **pvStorageSize.medium.postgresql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to PostgreSQL in a
cluster of [`size`](#size) medium. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 60Gi<br>
**Example**:

```yaml
pvStorageSize:
  medium:
    postgresql: 100Gi
```

## **pvStorageSize.small.cassandra**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Cassandra in a
cluster of [`size`](#size) small. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 30Gi<br>
**Example**:

```yaml
pvStorageSize:
  small:
    cassandra: 100Gi
```

## **pvStorageSize.small.elasticsearch**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to Elasticsearch
in a cluster of [`size`](#size) small. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 30Gi<br>
**Example**:

```yaml
pvStorageSize:
  small:
    elasticsearch: 100Gi
```

## **pvStorageSize.small.mysql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to MySQL in a
cluster of [`size`](#size) small. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 25Gi<br>
**Example**:

```yaml
pvStorageSize:
  small:
    mysql: 100Gi
```

## **pvStorageSize.small.postgresql**
**Required**: `false`<br>
**Description**: The size of the persistent volume assigned to PostgreSQL in a
cluster of [`size`](#size) small. This option is ignored if
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: 30Gi<br>
**Example**:

```yaml
pvStorageSize:
  small:
    postgresql: 100Gi
```

## **sysdig.anchoreLicensePath**
**Required**: `false`<br>
**Description**: This is the path relative to the values.yaml where the
anchore enterprise license yaml is located. This parameter is required if
`sysdig.configureScanningReporting` is configured to `true`.<br>
**Options**:<br>
**Default**: <br>
**Example**:

```yaml
sysdig:
  anchoreLicensePath: anchore-enterprise-license.yaml
```

## **sysdig.anchoreVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Anchore Core.<br>
**Options**:<br>
**Default**: 0.5.0.1<br>
**Example**:

```yaml
sysdig:
  anchoreVersion: 0.5.0.1
```

## **sysdig.anchoreEnterpriseVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Anchore reporting.<br>
**Options**:<br>
**Default**: v0.4.1<br>
**Example**:

```yaml
sysdig:
  anchoreEnterpriseVersion: 0.5.0.1
```

## **sysdig.cassandraVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Cassandra.<br>
**Options**:<br>
**Default**: 2.1.21.13<br>
**Example**:

```yaml
sysdig:
  cassandraVersion: 2.1.21.13
```

## **sysdig.cassandra.external**
**Required**: `false`<br>
**Description**: If set does not create a local Cassandra cluster, tries connecting to an external Cassandra cluster.
This can be used in conjunction with [`sysdig.cassandra.endpoint`](#sysdigcassandraendpoint) <br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
 cassandra:
  external: true
```

## **sysdig.cassandra.endpoint**
**Required**: `false`<br>
**Description**:  External Cassandra endpoint can be provided here. <br>
**Options**: <br>
**Default**: 'sysdigcloud-cassandra'<br>
**Example**:

```yaml
sysdig:
 cassandra:
  external: true
  endpoint: external.cassandra.cluster
```

## **sysdig.cassandra.secure**
**Required**: `false`<br>
**Description**: Enables cassandra server and clients to use authentication. <br>
**Options**: `true|false`<br>
**Default**:`false`<br>
**Example**:

```yaml
sysdig:
 cassandra:
   secure: true
   ssl: true
```

## **sysdig.cassandra.ssl**
**Required**: `false`<br>
**Description**: Enables cassandra server and clients communicate over ssl. <br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
 cassandra:
   secure: true
   ssl: true
```

## **sysdig.cassandra.user**
**Required**: `false`<br>
**Description**: Sets cassandra user. The only gotcha is the user cannot be a substring of sysdigcloud-cassandra.<br>
**Options**: <br>
**Default**: `sysdigcassandra`<br>
**Example**:

```yaml
sysdig:
 cassandra:
   user: cassandrauser
```

## **sysdig.cassandra.password**
**Required**: `false`<br>
**Description**: Sets cassandra password <br>
**Options**: <br>
**Default**: Autogenerated 16 alphanumeric characters<br>
**Example**:

```yaml
sysdig:
 cassandra:
   user: cassandrauser
   password: cassandrapassword
```

## **sysdig.cassandra.workloadName**
**Required**: `false`<br>
**Description**: Name assigned to the Cassandra objects(statefulset and
service)<br>
**Options**: <br>
**Default**: `sysdigcloud-cassandra`<br>
**Example**:

```yaml
sysdig:
 cassandra:
   workloadName: sysdigcloud-cassandra
```

## **sysdig.cassandra.customOverrides**
**Required**: `false`<br>
**Description**: The custom overrides of Cassandra's default configuration. The parameter
expects a YAML block of key-value pairs as described in the [Cassandra
documentation](https://docs.datastax.com/en/archived/cassandra/2.1/cassandra/configuration/configCassandra_yaml_r.html).<br>
**Options**:<br>
**Default**: <br>
**Example**:

```yaml
sysdig:
  cassandra:
    customOverrides: |
      hinted_handoff_enabled: false
      concurrent_compactors: 8
      read_request_timeout_in_ms: 10000
      write_request_timeout_in_ms: 10000
```

## **sysdig.cassandra.datacenterName**
**Required**: `false`<br>
**Description**: The datacenter name used for the [Cassandra
Snitch](http://cassandra.apache.org/doc/latest/operating/snitch.html).<br>
**Options**:<br>
**Default**:  In AWS the value is ec2Region as determined by the code
[here](https://github.com/apache/cassandra/blob/a85afbc7a83709da8d96d92fc4154675794ca7fb/src/java/org/apache/cassandra/locator/Ec2Snitch.java#L61-L63),
elsewhere defaults to an empty string. <br>
**Example**:

```yaml
sysdig:
  cassandra:
    datacenterName: my-cool-datacenter
```

## **sysdig.cassandra.jvmOptions**
**Required**: `false`<br>
**Description**: The custom configuration for Cassandra JVM.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  cassandra:
    jvmOptions: -Xms6G -Xmx6G -XX:+PrintGCDateStamps -XX:+PrintGCDetails
```

## **sysdig.cassandra.hostPathNodes**
**Required**: `false`<br>
**Description**: An array of node hostnames printed out by the `kubectl get node -o
name` command. These are the nodes where Cassandra hostPath persistent volumes should be created on. The number of nodes must be at minimum whatever the value of
[`sysdig.cassandraReplicaCount`](#sysdigcassandrareplicacount) is. This is
required if configured [`storageClassProvisioner`](#storageclassprovisioner)
is `hostPath`.<br>
**Options**:<br>
**Default**: [] <br>

**Example**:

```yaml
sysdig:
  cassandra:
    hostPathNodes:
      - my-cool-host1.com
      - my-cool-host2.com
      - my-cool-host3.com
      - my-cool-host4.com
      - my-cool-host5.com
      - my-cool-host6.com
```

## **sysdig.collectorPort**
**Required**: `false`<br>
**Description**: The port to publicly serve Sysdig collector on.<br>
_**Note**: collectorPort is not configurable in openshift deployments. It is always 443._<br>
**Options**: `1024-65535`<br>
**Default**: `6443` <br>
**Example**:

```yaml
sysdig:
  collectorPort: 7000
```

## **sysdig.configureScanningReporting**
**Required**: `false`<br>
**Description**: Specifies if image scanning and reporting feature should be
included in the Sysdig platform to be deployed.<br>
**Options**: `true|false`<br>
**Default**: `false` <br>
**Example**:

```yaml
sysdig:
  configureScanningReporting: true
```

## **sysdig.customCA**
**Required**: `false`<br>
**Description**:
The Sysdig platform may sometimes open connections over SSL to certain external services, including:
 - LDAP over SSL
 - SAML over SSL
 - OpenID Connect over SSL
 - HTTPS Proxies<br>
If the signing authorities for the certificates presented by these services are not well-known to the Sysdig Platform (e.g., if you maintain your own Certificate Authority), they are not trusted by default.

To allow the Sysdig platform to trust these certificates, use this configuration to upload one or more PEM-format CA certificates. You must ensure you've uploaded all certificates in the CA approval chain to the root CA.

This configuration when set expects certificates with .crt extension under certs/custom-java-certs/ in the same level as `values.yaml`<br>
**Options**: `true|false`<br>
**Default**: false<br>
**Example**:

```bash
#In the example directory structure below, certificate1.crt and certificate2.crt will be added to the trusted list.
bash-5.0$ find certs values.yaml
certs
certs/custom-java-certs
certs/custom-java-certs/certificate1.crt
certs/custom-java-certs/certificate2.crt
values.yaml
```

```yaml
sysdig:
  customCA: true
```

## **sysdig.dnsName**
**Required**: `true`<br>
**Description**: The domain name the Sysdig APIs will be served on.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  dnsName: my-awesome-domain-name.com
```

## **sysdig.elasticsearchVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Elasticsearch.<br>
**Options**:<br>
**Default**: 5.6.16.12<br>
**Example**:

```yaml
sysdig:
  elasticsearchVersion: 5.6.16.12
```

## **sysdig.haproxyVersion**
**Required**: `false`<br>
**Description**: The docker image tag of HAProxy ingress controller. The
parameter is relevant only when configured `deployment` is `kubernetes`.<br>
**Options**:<br>
**Default**: v0.7-beta.7<br>
**Example**:

```yaml
sysdig:
  haproxyVersion: v0.7-beta.7
```

## **sysdig.ingressNetworking**
**Required**: `false`<br>
**Description**: The networking construct used to expose the Sysdig API and collector.
* hostnetwork, sets the hostnetworking in ingress daemonset and opens host ports for api and collector. This does not create a service.
* loadbalancer, creates a service of type [`loadbalancer`](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)
* nodeport, creates a service of type [`nodeport`](https://kubernetes.io/docs/concepts/services-networking/#nodeport). The node ports can be customized with:
  * [`sysdig.ingressNetworkingInsecureApiNodePort`](#sysdigingressnetworkinginsecureapinodeport)
  * [`sysdig.ingressNetworkingApiNodePort`](#sysdigingressnetworkingapinodeport)
  * [`sysdig.ingressNetworkingCollectorNodePort`](#sysdigingressnetworkingcollectornodeport)

**Options**:
[`hostnetwork`](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#host-namespaces)|[`loadbalancer`](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)|[`nodeport`](https://kubernetes.io/docs/concepts/services-networking/#nodeport)

**Default**: `hostnetwork`
**Example**:

```yaml
sysdig:
  ingressNetworking: loadbalancer
```

## **sysdig.ingressNetworkingInsecureApiNodePort**
**Required**: `false`<br>
**Description**: When [`sysdig.ingressNetworking`](#sysdigingressnetworking)
is configured as `nodeport`, this is the NodePort requested by Installer
from Kubernetes for the Sysdig non-TLS API endpoint.<br>
**Options**: <br>
**Default**: `30000`
**Example**:

```yaml
sysdig:
  ingressNetworkingInsecureApiNodePort: 30000
```

## **sysdig.ingressNetworkingApiNodePort**
**Required**: `false`<br>
**Description**: When [`sysdig.ingressNetworking`](#sysdigingressnetworking)
is configured as `nodeport`, this is the NodePort requested by Installer
from Kubernetes for the Sysdig TLS API endpoint.<br>
**Options**: <br>
**Default**: `30001`
**Example**:

```yaml
sysdig:
  ingressNetworkingApiNodePort: 30001
```

## **sysdig.ingressNetworkingCollectorNodePort**
**Required**: `false`<br>
**Description**: When [`sysdig.ingressNetworking`](#sysdigingressnetworking)
is configured as `nodeport`, this is the NodePort requested by Installer
from Kubernetes for the Sysdig collector endpoint.<br>
**Options**: <br>
**Default**: `30002`
**Example**:

```yaml
sysdig:
  ingressNetworkingCollectorNodePort: 30002
```

## **sysdig.license**
**Required**: `true`<br>
**Description**: Sysdig license provided with the deployment.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  license: replace_with_your_license
```

## **sysdig.localVolumeProvisioner**
**Required**: `false`<br>
**Description**: The version of the localVolumeProvisioner.<br>
**Options**:<br>
**Default**: v2.3.2<br>
**Example**:

```yaml
sysdig:
  localVolumeProvisioner: v2.3.2
```

## **sysdig.monitorVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Monitor.<br>
**Options**:<br>
**Default**: 2.5.0.5132<br>
**Example**:

```yaml
sysdig:
  monitorVersion: 2.5.0.5132
```

## **sysdig.mysqlHa**
**Required**: `false`<br>
**Description**: Determines if mysql should run in HA mode.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
  mysqlHa: false
```

## **sysdig.mysqlHaVersion**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL used for HA.<br>
**Options**:<br>
**Default**: 8.0.16.2<br>
**Example**:

```yaml
sysdig:
  mysqlVersion: 8.0.16.2
```

## **sysdig.mysqlHaAgentVersion**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL Agent used for HA.<br>
**Options**:<br>
**Default**: 0.1.15<br>
**Example**:

```yaml
sysdig:
  mysqlVersion: 0.1.15
```

## **sysdig.mysqlVersion**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL.<br>
**Options**:<br>
**Default**: 5.6.44.0<br>
**Example**:

```yaml
sysdig:
  mysqlVersion: 5.6.44.0
```

## **sysdig.mysql.external**
**Required**: `false`<br>
**Description**: If set, the installer does not create a local mysql cluster
instead it sets up the sysdig platform to connect to the configured
[`sysdig.mysql.hostname`](#sysdigmysqlhostname) <br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
  mysql:
    external: true
```

## **sysdig.mysql.hostname**
**Required**: `false`<br>
**Description**: Name of the mySQL host that the sysdig platform components
should connect to.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
sysdig:
  mysql:
    hostname: mysql.foo.com
```

## **sysdig.mysql.hostPathNodes**
**Required**: `false`<br>
**Description**: An array of node hostnames printed out by the `kubectl get
node -o name` command. These are the nodes where MySQL hostPath persistent
volumes should be created on. The number of nodes must be at minimum whatever
the value of [`sysdig.mysqlReplicaCount`](#sysdigmysqlreplicacount) is. This
parameter is required if configured
[`storageClassProvisioner`](#storageclassprovisioner) is `hostPath`.<br>
**Options**:<br>
**Default**: [] <br>

**Example**:

```yaml
sysdig:
  mysql:
    hostPathNodes:
      - my-cool-host1.com
```

## **sysdig.mysql.password**
**Required**: `false`<br>
**Description**: The password of the MySQL user that the Sysdig Platform backend
components will use in communicating with MySQL.<br>
**Options**:<br>
**Default**: `mysql-admin`<br>

**Example**:

```yaml
sysdig:
  mysql:
    user: awesome-user
```

## **sysdig.mysql.user**
**Required**: `false`<br>
**Description**: The username of the MySQL user that the Sysdig Platform backend
components will use in communicating with MySQL.<br>
**Options**:<br>
**Default**: `mysql-admin`<br>

**Example**:

```yaml
sysdig:
  mysql:
    user: awesome-user
```

## **sysdig.openshiftUrl**
**Required**: `false`<br>
**Description**: Openshift API url along with its port number, this is
required if configured `deployment` is `openshift`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  openshiftUrl: https://api.my-awesome-openshift.com:6443
```

## **sysdig.openshiftUser**
**Required**: `false`<br>
**Description**: Username of the user to access the configured
`sysdig.openshiftUrl`, required if configured `deployment` is `openshift`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  openshiftUser: bob+alice
```

## **sysdig.openshiftPassword**
**Required**: `false`<br>
**Description**: Password of the user(`sysdig.openshiftUser`) to access the
configured `sysdig.openshiftUrl`, required if configured `deployment` is
`openshift`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  openshiftPassword: my-@w350m3-p@55w0rd
```

## **sysdig.postgresVersion**
**Required**: `false`<br>
**Description**: Docker image tag of Postgres, relevant when configured `apps`
is `monitor secure`.<br>
**Options**:<br>
**Default**: 10.6.10<br>
**Example**:

```yaml
sysdig:
  postgresVersion: 10.6.10
```

## **sysdig.postgresql.hostPathNodes**
**Required**: `false`<br>
**Description**: An array of node hostnames has shown in `kubectl get node -o
name` that postgresql hostPath persistent volumes should be created on. The
number of nodes must be at minimum whatever the value of
[`sysdig.postgresReplicaCount`](#sysdigpostgresreplicacount) is. This is
required if configured [`storageClassProvisioner`](#storageclassprovisioner)
is `hostPath`.<br>
**Options**:<br>
**Default**: [] <br>

**Example**:

```yaml
sysdig:
  postgresql:
    hostPathNodes:
      - my-cool-host1.com
```

## **sysdig.proxy.defaultNoProxy**
**Required**: `false`<br>
**Description**: Default comma separated list of addresses or domain names
that can be reached without going through the configured web proxy. This is
only relevant if [`sysdig.proxy.enable`](#sysdigproxyenable) is configured and
should only be used if there is an intent to override the defaults provided by
Installer otherwise consider [`sysdig.proxy.noProxy`](#sysdigproxynoproxy)
instead.<br>
**Options**:<br>
**Default**: `127.0.0.1, localhost, sysdigcloud-anchore-core, anchore-reports`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    defaultNoProxy: 127.0.0.1, localhost, sysdigcloud-anchore-core, anchore-reports
```

## **sysdig.proxy.enable**
**Required**: `false`<br>
**Description**: Determines if a [web
proxy](https://en.wikipedia.org/wiki/Proxy_server#Web_proxy_servers) should be
used by Anchore for fetching CVE feed from
[https://ancho.re.](https://ancho.re.)<br>
**Options**:<br>
**Default**: `false`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
```

## **sysdig.proxy.host**
**Required**: `false`<br>
**Description**: The address of the web proxy, this could be a domain name or
an IP address. This is required if [`sysdig.proxy.enable`](#sysdigproxyenable)
is configured.<br>
**Options**:<br>
**Default**:<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    host: my-awesome-proxy.my-awesome-domain.com
```

## **sysdig.proxy.noProxy**
**Required**: `false`<br>
**Description**: Comma separated list of addresses or domain names
that can be reached without going through the configured web proxy. This is
only relevant if [`sysdig.proxy.enable`](#sysdigproxyenable) is configured and
appended to the list in
[`sysdig.proxy.defaultNoProxy`](#sysdigproxydefaultnoproxy].<br>
**Options**:<br>
**Default**: `127.0.0.1, localhost, sysdigcloud-anchore-core, anchore-reports`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    noProxy: my-awesome.domain.com, 192.168.0.0/16
```

## **sysdig.proxy.password**
**Required**: `false`<br>
**Description**: The password used to access the configured
[`sysdig.proxy.host`](#sysdigproxyhost).<br>
**Options**:<br>
**Default**:<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    password: F00B@r!
```

## **sysdig.proxy.port**
**Required**: `false`<br>
**Description**: The port the configured
[`sysdig.proxy.host`](#sysdigproxyhost) is listening on. If this is not
configured it defaults to 80.<br>
**Options**:<br>
**Default**: `80`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    port: 3128
```

## **sysdig.proxy.protocol**
**Required**: `false`<br>
**Description**: The protocol to use to communicate with the configured
[`sysdig.proxy.host`](#sysdigproxyhost).<br>
**Options**: `http|https`<br>
**Default**: `http`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    protocol: https
```

## **sysdig.proxy.user**
**Required**: `false`<br>
**Description**: The user used to access the configured
[`sysdig.proxy.host`](#sysdigproxyhost).<br>
**Options**:<br>
**Default**:<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    user: alice
```


## **sysdig.redisVersion**
**Required**: `false`<br>
**Description**: Docker image tag of Redis.<br>
**Options**:<br>
**Default**: 4.0.12.6<br>
**Example**:

```yaml
sysdig:
  redisVersion: 4.0.12.6
```

## **sysdig.redisHaVersion**
**Required**: `true`<br>
**Description**: Docker image tag of HA Redis, relevant when configured
`sysdig.redisHa` is `true`.<br>
**Options**:<br>
**Default**: 4.0.12.6<br>
**Example**:

```yaml
sysdig:
  redisHaVersion: 4.0.12.6
```

## **sysdig.redisHa**
**Required**: `false`<br>
**Description**: Determines if redis should run in HA mode<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
  redisHa: false
```

## **sysdig.resources.cassandra.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to cassandra pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 2    |
| medium     | 4    |
| large      | 8    |

**Example**:

```yaml
sysdig:
  resources:
    cassandra:
      limits:
        cpu: 2
```

## **sysdig.resources.cassandra.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to cassandra pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 8Gi  |
| medium     | 8Gi  |
| large      | 8Gi  |

**Example**:

```yaml
sysdig:
  resources:
    cassandra:
      limits:
        memory: 8Gi
```

## **sysdig.resources.cassandra.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule cassandra pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 1      |
| medium     | 2      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    cassandra:
      requests:
        cpu: 2
```

## **sysdig.resources.cassandra.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule cassandra pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 2Gi    |
| medium     | 2Gi    |
| large      | 2Gi    |

**Example**:

```yaml
sysdig:
  resources:
    cassandra:
      requests:
        memory: 2Gi
```

## **sysdig.resources.elasticsearch.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to elasticsearch pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 2    |
| medium     | 4    |
| large      | 8    |

**Example**:

```yaml
sysdig:
  resources:
    elasticsearch:
      limits:
        cpu: 2
```

## **sysdig.resources.elasticsearch.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to elasticsearch pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 8Gi  |
| medium     | 8Gi  |
| large      | 8Gi  |

**Example**:

```yaml
sysdig:
  resources:
    elasticsearch:
      limits:
        memory: 8Gi
```

## **sysdig.resources.elasticsearch.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule elasticsearch pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 1      |
| medium     | 2      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    elasticsearch:
      requests:
        cpu: 2
```

## **sysdig.resources.elasticsearch.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule elasticsearch pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 4Gi    |

**Example**:

```yaml
sysdig:
  resources:
    elasticsearch:
      requests:
        memory: 2Gi
```

## **sysdig.resources.mysql-router.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to mysql-router pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 500m |
| medium     | 500m |
| large      | 500m |

**Example**:

```yaml
sysdig:
  resources:
    mysql-router:
      limits:
        cpu: 2
```

## **sysdig.resources.mysql-router.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to mysql-router pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits|
|------------|------|
| small      | 500Mi|
| medium     | 500Mi|
| large      | 500Mi|

**Example**:

```yaml
sysdig:
  resources:
    mysql-router:
      limits:
        memory: 8Gi
```

## **sysdig.resources.mysql-router.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule mysql-router pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 250m   |
| medium     | 250m   |
| large      | 250m   |

**Example**:

```yaml
sysdig:
  resources:
    mysql-router:
      requests:
        cpu: 2
```

## **sysdig.resources.mysql-router.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule mysql-router pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100Mi  |
| medium     | 100Mi  |
| large      | 100Mi  |

**Example**:

```yaml
sysdig:
  resources:
    mysql-router:
      requests:
        memory: 2Gi
```

## **sysdig.resources.mysql.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to mysql pods<br>
**Options**:<br>
**Default**:<br>

**Example**:

```yaml
sysdig:
  resources:
    mysql:
      limits:
        cpu: 2
```

## **sysdig.resources.mysql.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to mysql pods<br>
**Options**:<br>
**Default**:<br>

**Example**:

```yaml
sysdig:
  resources:
    mysql:
      limits:
        memory: 8Gi
```

## **sysdig.resources.mysql.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule mysql pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 500m   |
| medium     | 500m   |
| large      | 500m   |

**Example**:

```yaml
sysdig:
  resources:
    mysql:
      requests:
        cpu: 2
```

## **sysdig.resources.mysql.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule mysql pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 1Gi    |
| medium     | 1Gi    |
| large      | 1Gi    |

**Example**:

```yaml
sysdig:
  resources:
    mysql:
      requests:
        memory: 2Gi
```

## **sysdig.resources.postgresql.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to postgresql pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2      |
| medium     | 4      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    postgresql:
      limits:
        cpu: 2
```

## **sysdig.resources.postgresql.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to postgresql pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 8Gi    |


**Example**:

```yaml
sysdig:
  resources:
    postgresql:
      limits:
        memory: 8Gi
```

## **sysdig.resources.postgresql.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule postgresql pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 500m   |
| medium     | 1      |
| large      | 2      |

**Example**:

```yaml
sysdig:
  resources:
    postgresql:
      requests:
        cpu: 2
```

## **sysdig.resources.postgresql.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule postgresql pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 500Mi  |
| medium     | 1Gi    |
| large      | 2Gi    |

**Example**:

```yaml
sysdig:
  resources:
    postgresql:
      requests:
        memory: 2Gi
```

## **sysdig.resources.redis.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2      |
| medium     | 2      |
| large      | 2      |

**Example**:

```yaml
sysdig:
  resources:
    redis:
      limits:
        cpu: 2
```

## **sysdig.resources.redis.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to redis pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2Gi    |
| medium     | 2Gi    |
| large      | 2Gi    |


**Example**:

```yaml
sysdig:
  resources:
    redis:
      limits:
        memory: 1Gi
```

## **sysdig.resources.redis.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule redis pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100m   |
| medium     | 100m   |
| large      | 100m   |

**Example**:

```yaml
sysdig:
  resources:
    redis:
      requests:
        cpu: 2
```

## **sysdig.resources.redis.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule redis pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100Mi  |
| medium     | 100Mi  |
| large      | 100Mi  |

**Example**:

```yaml
sysdig:
  resources:
    redis:
      requests:
        memory: 2Gi
```

## **sysdig.resources.redis-primary.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis-primary pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2      |
| medium     | 2      |
| large      | 2      |

**Example**:

```yaml
sysdig:
  resources:
    redis-primary:
      limits:
        cpu: 2
```

## **sysdig.resources.redis-primary.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to redis-primary pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2Gi    |
| medium     | 2Gi    |
| large      | 2Gi    |


**Example**:

```yaml
sysdig:
  resources:
    redis-primary:
      limits:
        memory: 1Gi
```

## **sysdig.resources.redis-primary.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule redis-primary pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100m   |
| medium     | 100m   |
| large      | 100m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-primary:
      requests:
        cpu: 2
```

## **sysdig.resources.redis-primary.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule redis-primary pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100Mi  |
| medium     | 100Mi  |
| large      | 100Mi  |

**Example**:

```yaml
sysdig:
  resources:
    redis-primary:
      requests:
        memory: 2Gi
```

## **sysdig.resources.redis-secondary.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis-secondary pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2      |
| medium     | 2      |
| large      | 2      |

**Example**:

```yaml
sysdig:
  resources:
    redis-secondary:
      limits:
        cpu: 2
```

## **sysdig.resources.redis-secondary.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to redis-secondary pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 2Gi    |
| medium     | 2Gi    |
| large      | 2Gi    |


**Example**:

```yaml
sysdig:
  resources:
    redis-secondary:
      limits:
        memory: 1Gi
```

## **sysdig.resources.redis-secondary.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule redis-secondary pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100m   |
| medium     | 100m   |
| large      | 100m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-secondary:
      requests:
        cpu: 2
```

## **sysdig.resources.redis-secondary.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule redis-secondary pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      | 100Mi  |
| medium     | 100Mi  |
| large      | 100Mi  |

**Example**:

```yaml
sysdig:
  resources:
    redis-secondary:
      requests:
        memory: 2Gi
```

## **sysdig.resources.redis-sentinel.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 300m   |
| medium     | 300m   |
| large      | 300m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      limits:
        cpu: 2
```

## **sysdig.resources.redis-sentinel.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 20Mi   |
| medium     | 20Mi   |
| large      | 20Mi   |


**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      limits:
        memory: 10Mi
```

## **sysdig.resources.redis-sentinel.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  50m   |
| medium     |  50m   |
| large      |  50m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      requests:
        cpu: 2
```

## **sysdig.resources.redis-sentinel.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   5Mi  |
| medium     |   5Mi  |
| large      |   5Mi  |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      requests:
        memory: 200Mi
```

## **sysdig.resources.redis-sentinel.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 300m   |
| medium     | 300m   |
| large      | 300m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      limits:
        cpu: 2
```

## **sysdig.resources.redis-sentinel.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 20Mi   |
| medium     | 20Mi   |
| large      | 20Mi   |


**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      limits:
        memory: 10Mi
```

## **sysdig.resources.redis-sentinel.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  50m   |
| medium     |  50m   |
| large      |  50m   |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      requests:
        cpu: 2
```

## **sysdig.resources.redis-sentinel.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule redis-sentinel pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   5Mi  |
| medium     |   5Mi  |
| large      |   5Mi  |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      requests:
        memory: 200Mi
```

## **sysdig.resources.api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to api pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 16     |

**Example**:

```yaml
sysdig:
  resources:
    api:
      limits:
        cpu: 2
```

## **sysdig.resources.api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to api pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 16Gi   |


**Example**:

```yaml
sysdig:
  resources:
    api:
      limits:
        memory: 10Mi
```

## **sysdig.resources.api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule api pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  1     |
| medium     |  1     |
| large      |  4     |

**Example**:

```yaml
sysdig:
  resources:
    api:
      requests:
        cpu: 2
```

## **sysdig.resources.api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule api pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   4Gi  |

**Example**:

```yaml
sysdig:
  resources:
    api:
      requests:
        memory: 200Mi
```

## **sysdig.resources.worker.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 16     |

**Example**:

```yaml
sysdig:
  resources:
    worker:
      limits:
        cpu: 2
```

## **sysdig.resources.worker.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 16Gi   |


**Example**:

```yaml
sysdig:
  resources:
    worker:
      limits:
        memory: 10Mi
```

## **sysdig.resources.worker.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  1     |
| medium     |  1     |
| large      |  4     |

**Example**:

```yaml
sysdig:
  resources:
    worker:
      requests:
        cpu: 2
```

## **sysdig.resources.worker.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   4Gi  |

**Example**:

```yaml
sysdig:
  resources:
    worker:
      requests:
        memory: 200Mi
```

## **sysdig.resources.collector.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to collector pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 16     |

**Example**:

```yaml
sysdig:
  resources:
    collector:
      limits:
        cpu: 2
```

## **sysdig.resources.collector.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to collector pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 16Gi   |


**Example**:

```yaml
sysdig:
  resources:
    collector:
      limits:
        memory: 10Mi
```

## **sysdig.resources.collector.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule collector pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  1     |
| medium     |  1     |
| large      |  4     |

**Example**:

```yaml
sysdig:
  resources:
    collector:
      requests:
        cpu: 2
```

## **sysdig.resources.collector.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule collector pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   4Gi  |

**Example**:

```yaml
sysdig:
  resources:
    collector:
      requests:
        memory: 200Mi
```

## **sysdig.resources.anchore-core.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to anchore-core pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    anchore-core:
      limits:
        cpu: 2
```

## **sysdig.resources.anchore-core.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to anchore-core pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 4Gi    |


**Example**:

```yaml
sysdig:
  resources:
    anchore-core:
      limits:
        memory: 10Mi
```

## **sysdig.resources.anchore-core.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule anchore-core pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  500m  |
| medium     |  1     |
| large      |  1     |

**Example**:

```yaml
sysdig:
  resources:
    anchore-core:
      requests:
        cpu: 2
```

## **sysdig.resources.anchore-core.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule anchore-core pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   1Gi  |

**Example**:

```yaml
sysdig:
  resources:
    anchore-core:
      requests:
        memory: 200Mi
```

## **sysdig.resources.anchore-reports.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to anchore-reports pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 300m   |
| medium     | 300m   |
| large      | 300m   |

**Example**:

```yaml
sysdig:
  resources:
    anchore-reports:
      limits:
        cpu: 2
```

## **sysdig.resources.anchore-reports.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to anchore-reports pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 8Gi    |
| medium     | 8Gi    |
| large      | 8Gi    |


**Example**:

```yaml
sysdig:
  resources:
    anchore-reports:
      limits:
        memory: 10Mi
```

## **sysdig.resources.anchore-reports.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule anchore-reports pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  100m  |
| medium     |  100m  |
| large      |  100m  |

**Example**:

```yaml
sysdig:
  resources:
    anchore-reports:
      requests:
        cpu: 2
```

## **sysdig.resources.anchore-reports.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule anchore-reports pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   3Gi  |
| medium     |   3Gi  |
| large      |   3Gi  |

**Example**:

```yaml
sysdig:
  resources:
    anchore-reports:
      requests:
        memory: 200Mi
```

## **sysdig.resources.anchore-worker.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to anchore-worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    anchore-worker:
      limits:
        cpu: 2
```

## **sysdig.resources.anchore-worker.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to anchore-worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 4Gi    |


**Example**:

```yaml
sysdig:
  resources:
    anchore-worker:
      limits:
        memory: 10Mi
```

## **sysdig.resources.anchore-worker.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule anchore-worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  500m  |
| medium     |  1     |
| large      |  1     |

**Example**:

```yaml
sysdig:
  resources:
    anchore-worker:
      requests:
        cpu: 2
```

## **sysdig.resources.anchore-worker.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule anchore-worker pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   1Gi  |

**Example**:

```yaml
sysdig:
  resources:
    anchore-worker:
      requests:
        memory: 200Mi
```

## **sysdig.resources.scanning-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to scanning-api pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    scanning-api:
      limits:
        cpu: 2
```

## **sysdig.resources.scanning-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to scanning-api pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 4Gi    |


**Example**:

```yaml
sysdig:
  resources:
    scanning-api:
      limits:
        memory: 10Mi
```

## **sysdig.resources.scanning-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule scanning-api pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  500m  |
| medium     |  1     |
| large      |  1     |

**Example**:

```yaml
sysdig:
  resources:
    scanning-api:
      requests:
        cpu: 2
```

## **sysdig.resources.scanning-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule scanning-api pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   1Gi  |

**Example**:

```yaml
sysdig:
  resources:
    scanning-api:
      requests:
        memory: 200Mi
```


## **sysdig.resources.scanningalertmgr.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to scanningalertmgr pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4      |
| medium     | 4      |
| large      | 4      |

**Example**:

```yaml
sysdig:
  resources:
    scanningalertmgr:
      limits:
        cpu: 2
```

## **sysdig.resources.scanningalertmgr.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to scanningalertmgr pods<br>
**Options**:<br>
**Default**:

|cluster-size|limits  |
|------------|--------|
| small      | 4Gi    |
| medium     | 4Gi    |
| large      | 4Gi    |


**Example**:

```yaml
sysdig:
  resources:
    scanningalertmgr:
      limits:
        memory: 10Mi
```

## **sysdig.resources.scanningalertmgr.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule scanningalertmgr pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |  500m  |
| medium     |  1     |
| large      |  1     |

**Example**:

```yaml
sysdig:
  resources:
    scanningalertmgr:
      requests:
        cpu: 2
```

## **sysdig.resources.scanningalertmgr.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule scanningalertmgr pods<br>
**Options**:<br>
**Default**:

|cluster-size|requests|
|------------|--------|
| small      |   1Gi  |
| medium     |   1Gi  |
| large      |   1Gi  |

**Example**:

```yaml
sysdig:
  resources:
    scanningalertmgr:
      requests:
        memory: 200Mi
```

## **sysdig.restrictPasswordLogin**
**Required**: `false`<br>
**Description**: Restricts password login to only super admin user forcing all
non-default users to login using the configured
[IdP](https://en.wikipedia.org/wiki/Identity_provider).<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
sysdig:
  restrictPasswordLogin: true
```

## **sysdig.rsyslogVersion**
**Required**: `false`<br>
**Description**: Docker image tag of rsyslog, relevant only when configured
`deployment` is `kubernetes`.<br>
**Options**:<br>
**Default**: 8.34.0.5<br>
**Example**:

```yaml
sysdig:
  rsyslogVersion: 8.34.0.5
```

## **sysdig.smtpFromAddress**
**Required**: `false`<br>
**Description**: Email address to use for the FROM field of sent emails.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpFromAddress: from-address@my-company.com
```

## **sysdig.smtpPassword**
**Required**: `false`<br>
**Description**: Password for the configured `sysdig.smtpUser`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpPassword: my-@w350m3-p@55w0rd
```

## **sysdig.smtpProtocolSSL**
**Required**: `false`<br>
**Description**: Specifies if SSL should be used when sending emails via SMTP.<br>
**Options**: `true|false` <br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpProtocolSSL: true
```

## **sysdig.smtpProtocolTLS**
**Required**: `false`<br>
**Description**: Specifies if TLS should be used when sending emails via SMTP<br>
**Options**: `true|false` <br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpProtocolTLS: true
```

## **sysdig.smtpServer**
**Required**: `false`<br>
**Description**: SMTP server to use to send emails<br>
**Options**: <br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpServer: smtp.gmail.com
```

## **sysdig.smtpServerPort**
**Required**: `false`<br>
**Description**: Port of the configured `sysdig.smtpServer`<br>
**Options**: `1-65535`<br>
**Default**: `25`<br>
**Example**:

```yaml
sysdig:
  smtpServerPort: 587<br>
```

## **sysdig.smtpUser**
**Required**: `false`<br>
**Description**: User for the configured `sysdig.smtpServer`<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  smtpUser: bob+alice@gmail.com<br>
```

## **sysdig.tolerations**
**Required**: `false`<br>
**Description**:
[Toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
that will be created on Sysdig platform pods, this can be combined with
[nodeaffinityLabel.key](#nodeaffinityLabelkey) and
[nodeaffinityLabel.value](#nodeaffinityLabelvalue) to ensure only Sysdig
Platform pods run on particular nodes<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: sysdig
      effect: "NoSchedule"
```

## **sysdig.anchoreCoreReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig Anchore Core replicas, this is a noop for
clusters of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  1  |
| large      |  1  |

**Example**:

```yaml
sysdig:
  anchoreCoreReplicaCount: 5
```

## **sysdig.anchoreReportingReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig Anchore Reporting replicas, this is a noop
for clusters of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  1  |
| large      |  1  |

**Example**:

```yaml
sysdig:
  anchoreReportingReplicaCount: 5
```

## **sysdig.apiReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig API replicas, this is a noop for clusters of
`size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  3  |
| large      |  5  |

**Example**:

```yaml
sysdig:
  apiReplicaCount: 5
```

## **sysdig.cassandraReplicaCount**
**Required**: `false`<br>
**Description**: Number of Cassandra replicas, this is a noop for clusters of
`size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  3  |
| large      |  6  |

**Example**:

```yaml
sysdig:
  cassandraReplicaCount: 20
```

## **sysdig.collectorReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig collector replicas, this is a noop for
clusters of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  3  |
| large      |  5  |

**Example**:

```yaml
sysdig:
  collectorReplicaCount: 7
```

## **sysdig.elasticSearchReplicaCount**
**Required**: `false`<br>
**Description**: Number of ElasticSearch replicas, this is a noop for clusters of
`size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  3  |
| large      |  6  |

**Example**:

```yaml
sysdig:
  elasticSearchReplicaCount: 20
```

## **sysdig.workerReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig worker replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

|cluster-size|count|
|------------|-----|
| small      |  1  |
| medium     |  3  |
| large      |  5  |

**Example**:

```yaml
sysdig:
  workerReplicaCount: 7
```

## **sysdig.admin.username**
**Required**: `true`<br>
**Description**: Sysdig Platform super admin user. This will be used for
initial login to the web interface. Make sure this is a valid email address
that you can receive emails at.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  admin:
    username: my-awesome-email@my-awesome-domain-name.com
```

## **sysdig.admin.password**
**Required**: `false`<br>
**Description**: Sysdig Platform super admin password. This along with
`sysdig.admin.username` will be used for initial login to the web interface.
It is auto-generated when not explicitly configured.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  admin:
    password: my-@w350m3-p@55w0rd
```

## **sysdig.api.jvmOptions**
**Required**: `false`<br>
**Description**: Custom configuration for Sysdig API jvm.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  api:
    jvmOptions: -Xms4G -Xmx4G -Ddraios.jvm-monitoring.ticker.enabled=true
      -XX:-UseContainerSupport -Ddraios.metrics-push.query.enabled=true
```

## **sysdig.certificate.generate**
**Required**: `false`<br>
**Description**: Determines if Installer should generate self-signed
certificates for the domain configured in `sysdig.dnsName`.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
sysdig:
  certificate:
    generate: true
```

## **sysdig.certificate.crt**
**Required**: `false`<br>
**Description**: Path(the path must be in same directory as `values.yaml` file
and must be relative to `values.yaml`) to user provided certificate that will
be used in serving the Sysdig api, if `sysdig.certificate.generate` is set to
`false` this has to be configured. The certificate common name or subject
altername name must match configured `sysdig.dnsName`.<br>
**Options**:<br>
**Default**: `true`<br>
**Example**:

```yaml
sysdig:
  certificate:
    crt: certs/server.crt
```

## **sysdig.certificate.key**
**Required**: `false`<br>
**Description**: Path(the path must be in same directory as `values.yaml` file
and must be relative to `values.yaml`) to user provided key that will be used
in serving the sysdig api, if `sysdig.certificate.generate` is set to `false`
this has to be configured. The key must match the certificate in
`sysdig.certificate.crt`.<br>
**Options**:<br>
**Default**: `true`<br>
**Example**:

```yaml
sysdig:
  certificate:
    crt: certs/server.key
```

## **sysdig.collector.dnsName**
**Required**: `false`<br>
**Description**: Domain name the Sysdig collector will be served on, when not
configured it defaults to whatever is configured for `sysdig.dnsName`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  collector:
    dnsName: collector.my-awesome-domain-name.com
```

## **sysdig.collector.jvmOptions**
**Required**: `false`<br>
**Description**: Custom configuration for Sysdig collector jvm.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  collector:
    jvmOptions: -Xms4G -Xmx4G -Ddraios.jvm-monitoring.ticker.enabled=true
      -XX:-UseContainerSupport
```

## **sysdig.collector.certificate.generate**
**Required**: `false`<br>
**Description**: This determines if Installer should generate self-signed<br>
certificates for the domain configured in `sysdig.collector.dnsName`.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
sysdig:
  collector:
    certificate:
      generate: true
```

## **sysdig.collector.certificate.crt**
**Required**: `false`<br>
**Description**: Path(the path must be in same directory as `values.yaml` file
and must be relative to `values.yaml`) to user provided certificate that will
be used in serving the sysdig collector, if
`sysdig.collector.certificate.generate` is set to `false` this has to be
configured. The certificate common name or subject altername name must match
configured `sysdig.collector.dnsName`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  collector:
    certificate:
      crt: certs/collector.crt
```

## **sysdig.collector.certificate.key**
**Required**: `false`<br>
**Description**: Path(the path must be in same directory as `values.yaml` file
and must be relative to `values.yaml`) to user provided key that will be used
in serving the sysdig collector, if `sysdig.collector.certificate.generate` is
set to `false` this has to be configured. The key must match the certificate
in `sysdig.collector.certificate.crt`.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  collector:
    certificate:
      key: certs/collector.key
```

## **sysdig.worker.jvmOptions**
**Required**: `false`<br>
**Description**: Custom configuration for Sysdig worker jvm.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  worker:
    jvmOptions: -Xms4G -Xmx4G -Ddraios.jvm-monitoring.ticker.enabled=true
      -XX:-UseContainerSupport
```
