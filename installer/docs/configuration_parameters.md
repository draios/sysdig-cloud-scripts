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
**Required**: `false`<br>
**Description**: The name of the [storage class
provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner)
to use when creating the configured storageClassName parameter. Use hostPath
or local in clusters that do not have a provisioner. For setups where
Persistent Volumes and Persistent Volume Claims are created manually this
should be configured as `none`. If this is not configured
[`storageClassName`](#storageclassname) needs to be configured.<br>
**Options**: `aws|gke|hostPath|none`<br>
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
**Options**: `monitor|monitor secure|agent|monitor agent|monitor secure agent`<br>
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

## **airgapped_repository_prefix**
**Required**: `false`<br>
**Description**: This defines custom repository prefix for airgapped_registry.
Tags and pushes images as airgapped_registry_name/airgapped_repository_prefix/image_name:tag<br>
**Options**:<br>
**Default**: sysdig<br>
**Example**:

```yaml
#tags and pushes the image to <airgapped_registry_name>/foo/bar/<image_name:tag>
airgapped_repository_prefix: foo/bar
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

## **context**
**Required**: `false`<br>
**Description**: Kubernetes context to use for deploying Sysdig Platform.
If this param is not not or a blank value is specified, it will use the default context.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
context: production
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

## **elasticsearch.useES6**
**Required**: `false`<br>
**Description**: Install Elasticsearch 6.8.x along with user authentication and TLS-encrypted data-in-transit
using Elasticsearch's native TLS Encrpytion.
If TLS Encrpytion is enabled Installer does the following in the provided order:
  1. Checks for existing Elasticsearch certificates in the provided environment to setup ES cluster. (applicable for upgrades)
  2. If they are not present Installer autogenerates tls certificates and uses them to setup es cluster.
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
elasticsearch:
  useES6: true
```

## **elasticsearch.tlsencryption.adminUser**
**Required**: `false`<br>
**Description**: The user bound to the ElasticSearch admin role.<br>
**Options**: <br>
**Default**: `sysdig`<br>
**Example**:

```yaml
elasticsearch:
  tlsencryption:
    adminUser: admin
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

## **sysdig.activityAuditVersion**
**Required**: `false`<br>
**Description**: Docker image tag of Activity Audit services.<br>
**Options**:<br>
**Default**: [`sysdig.monitorVersion`](#sysdigmonitorversion)<br>
**Example**:

```yaml
sysdig:
  activityAuditVersion: 3.5.1.7018
```

## **sysdig.profilingVersion**
**Required**: `false`<br>
**Description**: Docker image tag of Profiling services.<br>
**Options**:<br>
**Default**: [`sysdig.monitorVersion`](#sysdigmonitorversion)<br>
**Example**:

```yaml
sysdig:
  profilingVersion: 3.5.1.7018
```

## **sysdig.anchoreVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Anchore Core.<br>
**Options**:<br>
**Default**: 0.6.1.2<br>
**Example**:

```yaml
sysdig:
  anchoreVersion: 0.6.1.6
```

## **sysdig.accessKey**
**Required**: `false`<br>
**Description**: The AWS (or AWS compatible) accessKey to be used by Sysdig
components to communicate with AWS (or an AWS compatible API).<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  accessKey: my_awesome_aws_access_key
```

## **sysdig.secretKey**
**Required**: `false`<br>
**Description**: The AWS (or AWS compatible) secretKey to be used by Sysdig
components to communicate with AWS (or an AWS compatible API).<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  secretKey: my_super_secret_secret_key
```

## **sysdig.s3.enabled**
**Required**: `false`<br>
**Description**: Specifies if storing Sysdig Captures in S3 or S3-compatible storage is enabled.<br>
**Options**:`true|false`<br>
**Default**:false<br>
**Example**:

```yaml
sysdig:
  s3:
    enabled: true
```

## **sysdig.s3.endpoint**
**Required**: `false`<br>
**Description**: S3-compatible endpoint for the bucket, this option is ignored if
[`sysdig.s3.enabled`](#sysdigs3enabled) is not configured. This option is not required if using an AWS S3 Bucket for captures.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  s3:
    endpoint: s3.us-south.cloud-object-storage.appdomain.cloud
```

## **sysdig.s3.bucketName**
**Required**: `false`<br>
**Description**: Name of the S3 bucket to be used for captures, this option is ignored if
[`sysdig.s3.enabled`](#sysdigs3enabled) is not configured.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
sysdig:
  s3:
    bucketName: my_awesome_bucket
```

## **sysdig.cassandraVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Cassandra.<br>
**Options**:<br>
**Default**: 2.1.21.13<br>
**Example**:

```yaml
sysdig:
  cassandraVersion: 2.1.21.16
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

## **sysdig.certificate.customCA**
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
  certificate:
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
**Default**: 5.6.16.18<br>
**Example**:

```yaml
sysdig:
  elasticsearchVersion: 5.6.16.18
```

## **sysdig.haproxyVersion**
**Required**: `false`<br>
**Description**: The docker image tag of HAProxy ingress controller. The
parameter is relevant only when configured `deployment` is `kubernetes`.<br>
**Options**:<br>
**Default**: v0.7-beta.7.1<br>
**Example**:

```yaml
sysdig:
  haproxyVersion: v0.7-beta.7.1
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
* external, assumes external ingress is used and does not create ingress objects.

**Options**:
[`hostnetwork`](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#host-namespaces)|[`loadbalancer`](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)|[`nodeport`](https://kubernetes.io/docs/concepts/services-networking/#nodeport)| external

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

## **sysdig.ingressLoadBalancerAnnotation**
**Required**: `false`<br>
**Description**: Annotations that will be added to the
`haproxy-ingress-service` object, this is useful to set annotations related to
creating internal loadbalancers.<br>
**Options**: <br>
**Example**:

```yaml
sysdig:
  ingressLoadBalancerAnnotation:
    cloud.google.com/load-balancer-type: Internal
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

## **sysdig.monitorVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Monitor. **Do not modify
this unless you know what you are doing as modifying it could have unintended
consequences**<br>
**Options**:<br>
**Default**: 3.5.1.7018<br>
**Example**:

```yaml
sysdig:
  monitorVersion: 3.5.1.7018
```

## **sysdig.scanningVersion**
**Required**: `false`<br>
**Description**: The docker image tag of the Sysdig Scanning components, if
this is not configured it defaults to `sysdig.monitorVersion` **Do not modify
this unless you know what you are doing as modifying it could have unintended
consequences**<br>
**Options**:<br>
**Default**: 3.5.1.7018<br>
**Example**:

```yaml
sysdig:
  scanningVersion: 3.5.1.7018
```

## **sysdig.sysdigAPIVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Sysdig API components, if
this is not configured it defaults to `sysdig.monitorVersion` **Do not modify
this unless you know what you are doing as modifying it could have unintended
consequences**<br>
**Options**:<br>
**Default**: 3.5.1.7018<br>
**Example**:

```yaml
sysdig:
  sysdigAPIVersion: 3.5.1.7018
```

## **sysdig.sysdigCollectorVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Sysdig Collector components, if
this is not configured it defaults to `sysdig.monitorVersion` **Do not modify
this unless you know what you are doing as modifying it could have unintended
consequences**<br>
**Options**:<br>
**Default**: 3.5.1.7018<br>
**Example**:

```yaml
sysdig:
  sysdigCollectorVersion: 3.5.1.7018
```

## **sysdig.sysdigWorkerVersion**
**Required**: `false`<br>
**Description**: The docker image tag of Sysdig Worker components, if
this is not configured it defaults to `sysdig.monitorVersion` **Do not modify
this unless you know what you are doing as modifying it could have unintended
consequences**<br>
**Options**:<br>
**Default**: 3.5.1.7018<br>
**Example**:

```yaml
sysdig:
  sysdigWorkerVersion: 3.5.1.7018
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

## **sysdig.useMySQL8**
**Required**: `false`<br>
**Description**: Determines if standalone mysql should run MySQL8.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
sysdig:
  useMySQL8: true
```

## **sysdig.mysqlHaVersion**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL used for HA.<br>
**Options**:<br>
**Default**: 8.0.16.4<br>
**Example**:

```yaml
sysdig:
  mysqlHaVersion: 8.0.16.4
```

## **sysdig.mysqlHaAgentVersion**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL Agent used for HA.<br>
**Options**:<br>
**Default**: 0.1.1.6<br>
**Example**:

```yaml
sysdig:
  mysqlHaAgentVersion: 0.1.1.6
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

## **sysdig.mysql8Version**
**Required**: `false`<br>
**Description**: The docker image tag of MySQL8.<br>
**Options**:<br>
**Default**: 8.0.16.0<br>
**Example**:

```yaml
sysdig:
  mysqlVersion: 8.0.16.0
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

## **sysdig.mysql.maxConnections**
**Required**: `false`<br>
**Description**: The maximum permitted number of simultaneous client connections.<br>
**Options**:<br>
**Default**: `1024`<br>

**Example**:

```yaml
sysdig:
  mysql:
    maxConnections: 1024
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
_**Note**: Do NOT use `root` user for this value._<br>
**Options**:<br>
**Default**: `mysql-admin`<br>

**Example**:

```yaml
sysdig:
  mysql:
    user: awesome-user
```

## **sysdig.natsExporterVersion**
**Required**: `false`<br>
**Description**: Docker image tag of the Prometheus exporter for NATS.<br>
**Options**:<br>
**Default**: 0.6.0.1<br>
**Example**:

```yaml
sysdig:
  natsExporterVersion: 0.6.0.1
```

## **sysdig.natsStreamingVersion**
**Required**: `false`<br>
**Description**: Docker image tag of NATS streaming.<br>
**Options**:<br>
**Default**: 0.16.2.1<br>
**Example**:

```yaml
sysdig:
  natsStreamingVersion: 0.16.2.1
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
**Default**: 10.6.11<br>
**Example**:

```yaml
sysdig:
  postgresVersion: 10.6.11
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
**Default**: `127.0.0.1, localhost, sysdigcloud-anchore-core`<br>

**Example**:

```yaml
sysdig:
  proxy:
    enable: true
    defaultNoProxy: 127.0.0.1, localhost, sysdigcloud-anchore-core
```

## **sysdig.proxy.enable**
**Required**: `false`<br>
**Description**: Determines if a [web
proxy](https://en.wikipedia.org/wiki/Proxy_server#Web_proxy_servers) should be
used by Anchore for fetching CVE feed from
[https://ancho.re](https://ancho.re.) and by the events forwarder to forward to HTTP based targets.<br>
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
**Default**: `127.0.0.1, localhost, sysdigcloud-anchore-core`<br>

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

## **sysdig.secure.anchore.customCerts**
**Required**: `false`<br>
**Description**:
To allow the Anchore to trust these certificates, use this configuration to upload one or more PEM-format CA certificates. You must ensure you've uploaded all certificates in the CA approval chain to the root CA.

This configuration when set expects certificates with .crt, .pem extension under certs/anchore-custom-certs/ in the same level as `values.yaml`<br>
**Options**: `true|false`<br>
**Default**: false<br>
**Example**:

```bash
#In the example directory structure below, certificate1.crt and certificate2.crt will be added to the trusted list.
bash-5.0$ find certs values.yaml
certs
certs/anchore-custom-certs
certs/anchore-custom-certs/certificate1.crt
certs/anchore-custom-certs/certificate2.crt
values.yaml
```

```yaml
sysdig:
  secure:
    anchore:
      customCerts: true
```

## **sysdig.redisVersion**
**Required**: `false`<br>
**Description**: Docker image tag of Redis.<br>
**Options**:<br>
**Default**: 4.0.12.7<br>
**Example**:

```yaml
sysdig:
  redisVersion: 4.0.12.7
```

## **sysdig.redisHaVersion**
**Required**: `false`<br>
**Description**: Docker image tag of HA Redis, relevant when configured
`sysdig.redisHa` is `true`.<br>
**Options**:<br>
**Default**: 4.0.12-1.0.1<br>
**Example**:

```yaml
sysdig:
  redisHaVersion: 4.0.12-1.0.1
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

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 4      |
| large        | 8      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 8Gi    |
| medium       | 8Gi    |
| large        | 8Gi    |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 2        |
| large        | 4        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 2Gi      |
| medium       | 2Gi      |
| large        | 2Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 4      |
| large        | 8      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 8Gi    |
| medium       | 8Gi    |
| large        | 8Gi    |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 2        |
| large        | 4        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 4Gi      |
| medium       | 4Gi      |
| large        | 4Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 500m   |
| medium       | 500m   |
| large        | 500m   |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 100Mi    |
| medium       | 100Mi    |
| large        | 100Mi    |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 500m     |
| large        | 500m     |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 4      |
| large        | 4      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 8Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 1        |
| large        | 2        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500Mi    |
| medium       | 1Gi      |
| large        | 2Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 2Gi    |
| medium       | 2Gi    |
| large        | 2Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 100m     |
| medium       | 100m     |
| large        | 100m     |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 100Mi    |
| medium       | 100Mi    |
| large        | 100Mi    |

**Example**:

```yaml
sysdig:
  resources:
    redis:
      requests:
        memory: 2Gi
```

## **sysdig.resources.redis-sentinel.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to redis-sentinel pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 300m   |
| medium       | 300m   |
| large        | 300m   |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 20Mi   |
| medium       | 20Mi   |
| large        | 20Mi   |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 50m      |
| medium       | 50m      |
| large        | 50m      |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 5Mi      |
| medium       | 5Mi      |
| large        | 5Mi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 300m   |
| medium       | 300m   |
| large        | 300m   |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 20Mi   |
| medium       | 20Mi   |
| large        | 20Mi   |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 50m      |
| medium       | 50m      |
| large        | 50m      |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 5Mi      |
| medium       | 5Mi      |
| large        | 5Mi      |

**Example**:

```yaml
sysdig:
  resources:
    redis-sentinel:
      requests:
        memory: 200Mi
```

## **sysdig.resources.timescale-adapter.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to timescale-adapter containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 16     |

**Example**:

```yaml
sysdig:
  resources:
    timescale-adapter:
      limits:
        cpu: 2
```

## **sysdig.resources.timescale-adapter.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to timescale-adapter containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 16Gi   |


**Example**:

```yaml
sysdig:
  resources:
    timescale-adapter:
      limits:
        memory: 10Mi
```

## **sysdig.resources.timescale-adapter.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule timescale-adapter containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 1        |
| large        | 4        |

**Example**:

```yaml
sysdig:
  resources:
    timescale-adapter:
      requests:
        cpu: 2
```

## **sysdig.resources.timescale-adapter.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule timescale-adapter containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 4Gi      |

**Example**:

```yaml
sysdig:
  resources:
    timescale-adapter:
      requests:
        memory: 200Mi
```

## **sysdig.resources.api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 16     |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 16Gi   |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 1        |
| large        | 4        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 4Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 16     |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 16Gi   |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 1        |
| large        | 4        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 4Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 16     |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 16Gi   |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 1        |
| large        | 4        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 4Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 4      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 4Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 1        |
| large        | 1        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

**Example**:

```yaml
sysdig:
  resources:
    anchore-core:
      requests:
        memory: 200Mi
```

## **sysdig.resources.anchore-worker.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to anchore-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 4      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 4Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 1        |
| large        | 1        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 4      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 4Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 1        |
| large        | 1        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 4      |

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

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 4Gi    |


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

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 1        |
| large        | 1        |

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

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

**Example**:

```yaml
sysdig:
  resources:
    scanningalertmgr:
      requests:
        memory: 200Mi
```

## **sysdig.resources.policy-advisor.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to policy-advisor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4      |
| medium       | 4      |
| large        | 4      |

**Example**:

```yaml
sysdig:
  resources:
    policy-advisor:
      limits:
        cpu: 2
```

## **sysdig.resources.policy-advisor.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to policy-advisor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 4Gi    |
| medium       | 4Gi    |
| large        | 4Gi    |


**Example**:

```yaml
sysdig:
  resources:
    policy-advisor:
      limits:
        memory: 10Mi
```

## **sysdig.resources.policy-advisor.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule policy-advisor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 1        |
| large        | 1        |

**Example**:

```yaml
sysdig:
  resources:
    policy-advisor:
      requests:
        cpu: 2
```

## **sysdig.resources.policy-advisor.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule policy-advisor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

**Example**:

```yaml
sysdig:
  resources:
    policy-advisor:
      requests:
        memory: 200Mi
```

## **sysdig.resources.nats-streaming.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to nats-streaming pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    nats-streaming:
      limits:
        cpu: 2
```

## **sysdig.resources.nats-streaming.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to nats-streaming pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2Gi    |
| medium       | 2Gi    |
| large        | 2Gi    |


**Example**:

```yaml
sysdig:
  resources:
    nats-streaming:
      limits:
        memory: 2Gi
```

## **sysdig.resources.nats-streaming.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule nats-streaming pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    nats-streaming:
      requests:
        cpu: 250m
```

## **sysdig.resources.nats-streaming.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule nats-streaming pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 1Gi      |
| large        | 1Gi      |

**Example**:

```yaml
sysdig:
  resources:
    nats-streaming:
      requests:
        memory: 1Gi
```

## **sysdig.resources.activity-audit-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to activity-audit-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-api:
      limits:
        cpu: 2
```

## **sysdig.resources.activity-audit-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to activity-audit-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-api:
      limits:
        memory: 500Mi
```

## **sysdig.resources.activity-audit-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule activity-audit-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-api:
      requests:
        cpu: 250m
```

## **sysdig.resources.activity-audit-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule activity-audit-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-api:
      requests:
        memory: 50Mi
```

## **sysdig.resources.activity-audit-worker.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to activity-audit-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-worker:
      limits:
        cpu: 1
```

## **sysdig.resources.activity-audit-worker.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to activity-audit-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |


**Example**:

```yaml
sysdig:
  resources:
    activity-audit-worker:
      limits:
        memory: 500Mi
```

## **sysdig.resources.activity-audit-worker.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule activity-audit-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-worker:
      requests:
        cpu: 250m
```

## **sysdig.resources.activity-audit-worker.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule activity-audit-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-worker:
      requests:
        memory: 50Mi
```

## **sysdig.resources.activity-audit-janitor.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to activity-audit-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 250m   |
| medium       | 250m   |
| large        | 250m   |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-janitor:
      limits:
        cpu: 250m
```

## **sysdig.resources.activity-audit-janitor.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to activity-audit-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 200Mi  |
| medium       | 200Mi  |
| large        | 200Mi  |


**Example**:

```yaml
sysdig:
  resources:
    activity-audit-janitor:
      limits:
        memory: 200Mi
```

## **sysdig.resources.activity-audit-janitor.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule activity-audit-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-janitor:
      requests:
        cpu: 250m
```

## **sysdig.resources.activity-audit-janitor.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule activity-audit-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    activity-audit-janitor:
      requests:
        memory: 50Mi
```

## **sysdig.resources.profiling-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to profiling-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    profiling-api:
      limits:
        cpu: 2
```

## **sysdig.resources.profiling-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to profiling-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

**Example**:

```yaml
sysdig:
  resources:
    profiling-api:
      limits:
        memory: 500Mi
```

## **sysdig.resources.profiling-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule profiling-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    profiling-api:
      requests:
        cpu: 250m
```

## **sysdig.resources.profiling-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule profiling-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    profiling-api:
      requests:
        memory: 50Mi
```

## **sysdig.resources.profiling-worker.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to profiling-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    profiling-worker:
      limits:
        cpu: 1
```

## **sysdig.resources.profiling-worker.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to profiling-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |


**Example**:

```yaml
sysdig:
  resources:
    profiling-worker:
      limits:
        memory: 500Mi
```

## **sysdig.resources.profiling-worker.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule profiling-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    profiling-worker:
      requests:
        cpu: 250m
```

## **sysdig.resources.profiling-worker.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule profiling-worker pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    profiling-worker:
      requests:
        memory: 50Mi
```

## **sysdig.resources.secure-overview-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to secure-overview-api containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    secure-overview-api:
      limits:
        cpu: 2
```

## **sysdig.resources.secure-overview-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to secure-overview-api containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1Gi    |
| medium       | 1Gi    |
| large        | 1Gi    |


**Example**:

```yaml
sysdig:
  resources:
    secure-overview-api:
      limits:
        memory: 1Gi
```

## **sysdig.resources.secure-overview-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule secure-overview-api containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 500m     |
| large        | 500m     |

**Example**:

```yaml
sysdig:
  resources:
    secure-overview-api:
      requests:
        cpu: 500m
```

## **sysdig.resources.secure-overview-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule secure-overview-api containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 512Mi    |
| medium       | 512Mi    |
| large        | 512Mi    |

**Example**:

```yaml
sysdig:
  resources:
    secure-overview-api:
      requests:
        memory: 512Mi
```

## **sysdig.resources.secure-prometheus.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to secure-prometheus containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    secure-prometheus:
      limits:
        cpu: 2
```

## **sysdig.resources.secure-prometheus.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to secure-prometheus containers<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 8Gi    |
| medium       | 8Gi    |
| large        | 8Gi    |


**Example**:

```yaml
sysdig:
  resources:
    secure-prometheus:
      limits:
        memory: 8Gi
```

## **sysdig.resources.secure-prometheus.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule secure-prometheus containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 500m     |
| medium       | 500m     |
| large        | 500m     |

**Example**:

```yaml
sysdig:
  resources:
    secure-prometheus:
      requests:
        cpu: 500m
```

## **sysdig.resources.secure-prometheus.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule secure-prometheus containers<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 2Gi      |
| medium       | 2Gi      |
| large        | 2Gi      |

**Example**:

```yaml
sysdig:
  resources:
    secure-prometheus:
      requests:
        memory: 2Gi
```

## **sysdig.resources.events-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    events-api:
      limits:
        cpu: 1
```

## **sysdig.resources.events-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

**Example**:

```yaml
sysdig:
  resources:
    events-api:
      limits:
        memory: 500Mi
```

## **sysdig.resources.events-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-api:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    events-api:
      requests:
        memory: 50Mi
```

## **sysdig.resources.events-gatherer.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-gatherer pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 2      |
| medium       | 2      |
| large        | 2      |

**Example**:

```yaml
sysdig:
  resources:
    events-gatherer:
      limits:
        cpu: 2
```

## **sysdig.resources.events-gatherer.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-gatherer pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1Gi    |
| medium       | 1Gi    |
| large        | 1Gi    |

**Example**:

```yaml
sysdig:
  resources:
    events-gatherer:
      limits:
        memory: 1Gi
```

## **sysdig.resources.events-gatherer.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-gatherer pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-gatherer:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-gatherer.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-gatherer pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250Mi    |
| medium       | 250Mi    |
| large        | 250Mi    |

**Example**:

```yaml
sysdig:
  resources:
    events-gatherer:
      requests:
        memory: 250Mi
```

## **sysdig.resources.events-dispatcher.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-dispatcher pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    events-dispatcher:
      limits:
        cpu: 1
```

## **sysdig.resources.events-dispatcher.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-dispatcher pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 250Mi  |
| medium       | 250Mi  |
| large        | 250Mi  |

**Example**:

```yaml
sysdig:
  resources:
    events-dispatcher:
      limits:
        memory: 250Mi
```

## **sysdig.resources.events-dispatcher.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-dispatcher pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-dispatcher:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-dispatcher.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-dispatcher pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    events-dispatcher:
      requests:
        memory: 50Mi
```

## **sysdig.resources.events-forwarder-api.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-forwarder-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder-api:
      limits:
        cpu: 1
```

## **sysdig.resources.events-forwarder-api.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-forwarder-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder-api:
      limits:
        memory: 500Mi
```

## **sysdig.resources.events-forwarder-api.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-forwarder-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder-api:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-forwarder-api.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-forwarder-api pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder-api:
      requests:
        memory: 50Mi
```

## **sysdig.resources.events-forwarder.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-forwarder pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder:
      limits:
        cpu: 1
```

## **sysdig.resources.events-forwarder.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-forwarder pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 500Mi  |
| medium       | 500Mi  |
| large        | 500Mi  |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder:
      limits:
        memory: 500Mi
```

## **sysdig.resources.events-forwarder.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-forwarder pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-forwarder.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-forwarder pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    events-forwarder:
      requests:
        memory:  50Mi
```

## **sysdig.resources.events-janitor.limits.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu assigned to events-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 1      |
| medium       | 1      |
| large        | 1      |

**Example**:

```yaml
sysdig:
  resources:
    events-janitor:
      limits:
        cpu: 1
```

## **sysdig.resources.events-janitor.limits.memory**
**Required**: `false`<br>
**Description**: The amount of memory assigned to events-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 200Mi  |
| medium       | 200Mi  |
| large        | 200Mi  |


**Example**:

```yaml
sysdig:
  resources:
    events-janitor:
      limits:
        memory: 200Mi
```

## **sysdig.resources.events-janitor.requests.cpu**
**Required**: `false`<br>
**Description**: The amount of cpu required to schedule events-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 250m     |
| medium       | 250m     |
| large        | 250m     |

**Example**:

```yaml
sysdig:
  resources:
    events-janitor:
      requests:
        cpu: 250m
```

## **sysdig.resources.events-janitor.requests.memory**
**Required**: `false`<br>
**Description**: The amount of memory required to schedule events-janitor pods<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 50Mi     |
| medium       | 50Mi     |
| large        | 50Mi     |

**Example**:

```yaml
sysdig:
  resources:
    events-janitor:
      requests:
        memory: 50Mi
```

## **sysdig.restrictPasswordLogin**
**Required**: `false`<br>
**Description**: Restricts password login to only super admin user forcing all
non-default users to login using the configured
[IdP](https://en.wikipedia.org/wiki/Identity_provider).<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
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
**Default**: 8.34.0.7<br>
**Example**:

```yaml
sysdig:
  rsyslogVersion: 8.34.0.7
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

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  anchoreCoreReplicaCount: 5
```

## **sysdig.anchoreWorkerReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig Anchore Worker replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  anchoreWorkerReplicaCount: 5
```

## **sysdig.apiReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig API replicas, this is a noop for clusters of
`size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 3     |
| large        | 5     |

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

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 3     |
| large        | 6     |

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

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 3     |
| large        | 5     |

**Example**:

```yaml
sysdig:
  collectorReplicaCount: 7
```

## **sysdig.activityAuditWorkerReplicaCount**
**Required**: `false`<br>
**Description**: Number of Activity Audit Worker replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 2     |
| large        | 4     |

**Example**:

```yaml
sysdig:
  activityAuditWorkerReplicaCount: 20
```

## **sysdig.activityAuditApiReplicaCount**
**Required**: `false`<br>
**Description**: Number of Activity Audit API replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  activityAuditApiReplicaCount: 20
```

## **sysdig.policyAdvisorReplicaCount**
**Required**: `false`<br>
**Description**: Number of Policy Advisor replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  policyAdvisorReplicaCount: 20
```

## **sysdig.anchoreCoreReplicaCount**
**Required**: `false`<br>
**Description**: Number of Anchore Core replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  anchoreCoreReplicaCount: 2
```

## **sysdig.scanningApiReplicaCount**
**Required**: `false`<br>
**Description**: Number of Scanning API replicas.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  scanningApiReplicaCount: 3
```

## **sysdig.elasticsearchReplicaCount**
**Required**: `false`<br>
**Description**: Number of ElasticSearch replicas, this is a noop for clusters of
`size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 3     |
| large        | 6     |

**Example**:

```yaml
sysdig:
  elasticsearchReplicaCount: 20
```

## **sysdig.workerReplicaCount**
**Required**: `false`<br>
**Description**: Number of Sysdig worker replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 3     |
| large        | 5     |

**Example**:

```yaml
sysdig:
  workerReplicaCount: 7
```

## **sysdig.eventsGathererReplicaCount**
**Required**: `false`<br>
**Description**: Number of events gatherer replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 2     |
| large        | 4     |

**Example**:

```yaml
sysdig:
  eventsGathererReplicaCount: 2
```

## **sysdig.eventsAPIReplicaCount**
**Required**: `false`<br>
**Description**: Number of events API replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  eventsAPIReplicaCount: 1
```

## **sysdig.eventsDispatcherReplicaCount**
**Required**: `false`<br>
**Description**: Number of events dispatcher replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  eventsDispatcherReplicaCount: 1
```

## **sysdig.eventsForwarderReplicaCount**
**Required**: `false`<br>
**Description**: Number of events forwarder replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 2     |

**Example**:

```yaml
sysdig:
  eventsForwarderReplicaCount: 2
```

## **sysdig.eventsForwarderAPIReplicaCount**
**Required**: `false`<br>
**Description**: Number of events forwarder API replicas, this is a noop for clusters
of `size` `small`.<br>
**Options**:<br>
**Default**:<br>

| cluster-size | count |
| ------------ | ----- |
| small        | 1     |
| medium       | 1     |
| large        | 1     |

**Example**:

```yaml
sysdig:
  eventsForwarderAPIReplicaCount: 1
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
    key: certs/server.key
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

## **agent.apiKey**
**Required**: `false`<br>
**Description**: Sysdig Agent api key for running agents. Instructions for retrieving the api key can be found [here](https://docs.sysdig.com/en/agent-installation--overview-and-key.html).<br>
_**Note**: Required for agent setup. If setting up Monitor and Agent at the same time, you can leave this as blank._<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
agent:
  apiKey: replace_with_your_monitor_access_key
```

## **agent.appChecks.settings.limit**
**Required**: `false`<br>
**Description**: The maximum number of app checks metrics that will be reported to Sysdig Monitor.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
agent:
  appChecks:
    settings:
      limit: 1500
```

## **agent.collectorEndpoint**
**Required**: `false`<br>
**Description**: Sysdig Collector Address. Defaults to [`sysdig.collector.dnsName`](#sysdig.collector.dnsName) if monitor is included in apps.<br>
**Options**:<br>
**Default**:<br>
**Example**:

```yaml
agent:
  collectorEndpoint: my-awesome-collector-domain-name.com
```

## **agent.collectorPort**
**Required**: `false`<br>
**Description**: Sysdig Colletor TCP Port.<br>
**Options**: `1024-65535`<br>
**Default**: `6443`<br>
**Example**:

```yaml
agent:
  collectorPort: 6443
```

## **agent.namespace**
**Required**: `false`<br>
**Description**: A kubernetes namespace for setting up the agent in.<br>
**Options**: <br>
**Default**: `agent`<br>
**Example**:

```yaml
agent:
  namespace: sysdig-agent
```

## **agent.useSlim**
**Required**: `false`<br>
**Description**: Whether to use the slim version of agent or not.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  useSlim: true
```

## **agent.version**
**Required**: `false`<br>
**Description**: Version of agent to install.<br>
_**Note**: You can lookup all the available versions of agent [here](https://hub.docker.com/r/sysdig/agent/tags)_<br>
**Options**: <br>
**Default**: `latest`<br>
**Example**:

```yaml
agent:
  version: 1.10.1
```

## **agent.useSSL**
**Required**: `false`<br>
**Description**: Whether Sysdig Collector accepts SSL connections or not.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  useSSL: false
```

## **agent.verifySSL**
**Required**: `false`<br>
**Description**: Whether to validate Sysdig Collector SSL certificate or not.<br>
_**Note**: This should be set to false if a self-signed certificate or private, CA-signed cert is used._<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  verifySSL: false
```

## **agent.clusterName**
**Required**: `false`<br>
**Description**: Setting a cluster name here allows you to view, scope, and segment metrics in the Sysdig Monitor UI by Kubernetes cluster.<br>
**Options**: <br>
**Default**: `production`<br>
**Example**:

```yaml
agent:
  clusterName: false
```

## **agent.tags**
**Required**: `false`<br>
**Description**: List of user-provided metadata at agent level.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  tags: environment:production linux:ubuntu
```

## **agent.capturesEnabled**
**Required**: `false`<br>
**Description**: TBD.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  capturesEnabled: false
```

## **agent.timezone**
**Required**: `false`<br>
**Description**: Set daemonset timezone.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  timezone: America/New_York.
```

## **agent.proxy.httpProxy**
**Required**: `false`<br>
**Description**: The URL to use as a proxy for http requests. If the proxy requires authentication, you need to specify this information as part of the URL.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  proxy:
    httpProxy: http://username:password@your-awesome-http-proxy.com
```

## **agent.proxy.httpsProxy**
**Required**: `false`<br>
**Description**: The URL to use as a proxy for https requests. If the proxy requires authentication, you need to specify this information as part of the URL.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  proxy:
    httpsProxy: https://username:password@your-awesome-https-proxy.com
```

## **agent.proxy.noProxy**
**Required**: `false`<br>
**Description**: A space-separated list of URLs for which no proxy should be used.<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  proxy:
    noProxy: your-awesome-no-proxy.com
```

## **agent.customKernelModules.enabled**
**Required**: `false`<br>
**Description**: Whether to pick up custom kernel modules from /root or not. This setting only applies to non-slim agent.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  customKernelModules:
    enabled: true
```

## **agent.secure.enabled**
**Required**: `false`<br>
**Description**: Whether your Sysdig platform has Sysdig Secure enabled or not.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  secure:
    enabled: true
```

## **agent.secure.commandLineCapturesEnabled**
**Required**: `false`<br>
**Description**: Whether you want to enable Command Line Captures or not.<br>
_**Note**: This setting is dependent on `agent.secure.enabled` being set to `true`._<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  secure:
    commandLineCapturesEnabled: true
```

## **agent.secure.memoryDumpEnabled**
**Required**: `false`<br>
**Description**: Whether you want to enable Memory Dump or not.<br>
_**Note**: This setting is dependent on `agent.secure.enabled` being set to `true`._<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  secure:
    memoryDumpEnabled: true
```

## **agent.secure.settings.k8sAuditServerURL**
**Required**: `false`<br>
**Description**: Kubernetes Audit Server URL.<br>
_**Note**: This setting is dependent on `agent.secure.enabled` being set to `true`._<br>
**Options**: <br>
**Default**: `0.0.0.0`<br>
**Example**:

```yaml
agent:
  secure:
    settings:
    k8sAuditServerURL: 127.0.0.1
```

## **agent.secure.settings.k8sAuditServerPort**
**Required**: `false`<br>
**Description**: Kubernetes Audit Server Port.<br>
_**Note**: This setting is dependent on `agent.secure.enabled` being set to `true`._<br>
**Options**: `1024-65535`<br>
**Default**: `7765`<br>
**Example**:

```yaml
agent:
  secure:
    settings:
    k8sAuditServerPort: 7765
```

## **agent.prometheus.enabled**
**Required**: `false`<br>
**Description**: Whether to enable ingestion of prometheus metrics or not.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  prometheus:
    enabled: true
```

## **agent.prometheus.settings.interval**
**Required**: `false`<br>
**Description**: How often (in seconds) the agent will scrape a port for prometheus metrics.<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: <br>
**Default**: `10`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      interval: 30
```

## **agent.prometheus.settings.logErrors**
**Required**: `false`<br>
**Description**: Whether the Agent should log details on failed attempts to scrape eligible targets or not.<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      logErrors: true
```

## **agent.prometheus.settings.maxMetrics**
**Required**: `false`<br>
**Description**: The maximum number of total prometheus metrics that will be scraped across all targets. This value is the maximum per-Agent, and is a separate limit from other Custom Metrics (e.g. statsd, JMX, and other Application Checks).<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: <br>
**Default**: `3000`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      maxMetrics: 1000
```

## **agent.prometheus.settings.maxMetricsPerProcess**
**Required**: `false`<br>
**Description**: The maximum number of prometheus metrics that the agent will save from a single scraped target.<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: <br>
**Default**: `3000`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      maxMetricsPerProcess: 1000
```

## **agent.prometheus.settings.maxTagsPerMetric**
**Required**: `false`<br>
**Description**: The maximum number of tags per prometheus metric that the Agent will save from a scraped target.<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: <br>
**Default**: `200`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      maxTagsPerMetric: 20
```

## **agent.prometheus.settings.histograms**
**Required**: `false`<br>
**Description**: Whether the Agent should scrape and report histogram metrics.<br>
_**Note**: This setting is dependent on `agent.prometheus.enabled` being set to true._<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  prometheus:
    settings:
      histograms: 3000
```

## **agent.statsd.enabled**
**Required**: `false`<br>
**Description**: Whether to enable ingestion of statsd metrics or not.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  statsd:
    enabled: true
```

## **agent.statsd.settings.limit**
**Required**: `false`<br>
**Description**: The maximum number of statsd metrics that will be reported to Sysdig Monitor.<br>
**Options**: <br>
**Default**: `100`<br>
**Example**:

```yaml
agent:
  statsd:
    settings:
      limit: 1000
```

## **agent.jmx.enabled**
**Required**: `false`<br>
**Description**: Whether to enable ingestion of jvm metrics via jmx protocol or not. If enabled, the agent will discover java virtual machines and poll them for basic jvm metrics like heap and gc as well as a few application sepecific metrics.<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  jmx:
    enabled: true
```

## **agent.jmx.settings.limit**
**Required**: `false`<br>
**Description**: The total number of JMX metrics polled per host.<br>
**Options**: <br>
**Default**: `3000`<br>
**Example**:

```yaml
agent:
  jmx:
    settings:
      limit: 1000
```

## **agent.ebpf.enabled**
**Required**: `false`<br>
**Description**: Enable eBPF support for Sysdig instead of sysdig-probe kernel module.<br>
_**Note**: This should be enabled for GKE COS as the installation of sysdig-probe kernel is not allowed._<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  ebpf:
    enabled: true
```

## **agent.ebpf.settings.mountEtcVolume**
**Required**: `false`<br>
**Description**: Needed to detect which kernel version are running in Google COS.<br>
_**Note**: This should be configured appropriately for GKE COS as the installation of sysdig-probe kernel is not allowed._<br>
**Options**: `true|false`<br>
**Default**: `true`<br>
**Example**:

```yaml
agent:
  ebpf:
    settings:
      mountEtcVolume: 1000
```

## **agent.appChecks.elasticsearch.authEnabled**
**Required**: `false`<br>
**Description**: Whether elasticsearch has auth enabled or not.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      authEnabled: true
```

## **agent.appChecks.elasticsearch.url**
**Required**: `false`<br>
**Description**: Elasticsearch Endpoint.<br>
_**Note**: This should be configured if `agent.appChecks.elasticsearch.authEnabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      url: https://sysdigcloud-elasticsearch
```

## **agent.appChecks.elasticsearch.port**
**Required**: `false`<br>
**Description**: Elasticsearch Port.<br>
_**Note**: This should be configured if `agent.appChecks.elasticsearch.authEnabled` is set to `true`._<br>
**Options**: `1024-65535`<br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      port: 9200
```

## **agent.appChecks.elasticsearch.username**
**Required**: `false`<br>
**Description**: Username to use for authentication to elasticsearch.<br>
_**Note**: This should be configured if `agent.appChecks.elasticsearch.authEnabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      username: readonly
```

## **agent.appChecks.elasticsearch.password**
**Required**: `false`<br>
**Description**: Password to use for authentication to elasticsearch.<br>
_**Note**: This should be configured if `agent.appChecks.elasticsearch.authEnabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      password: some_password
```

## **agent.appChecks.elasticsearch.verifySSL**
**Required**: `false`<br>
**Description**: Whether to validate Elasticsearch SSL certificate or not.<br>
_**Note**: This should be configured if `agent.appChecks.elasticsearch.authEnabled` is set to `true`._<br>
**Options**: `true|false`<br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    elasticsearch:
      verifySSL: false
```

## **agent.appChecks.kafka.enabled**
**Required**: `false`<br>enabled
**Description**: Whether to enable collection of metrics for kafka using JMX polling or not.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      enabled: true
```

## **agent.appChecks.kafka.arg**
**Required**: `false`<br>enabled
**Description**: Process arguments to match for Kafka<br>
_**Note**: This should be configured if `agent.appChecks.kafka.enabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      arg: Kafka.kafka
```

## **agent.appChecks.kafka.url**
**Required**: `false`<br>
**Description**: Kafka Endpoint.<br>
_**Note**: This should be configured if `agent.appChecks.kafka.enabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:enabled
  appChecks:
    kafka:
      url: localhost
```

## **agent.appChecks.kafka.port**
**Required**: `false`<br>
**Description**: Kafka Port.<br>
_**Note**: This should be configured if `agent.appChecks.kafka.enabled` is set to `true`._<br>
**Options**: `1024-65535`<br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      port: 9200
```

## **agent.appChecks.kafka.zk.url**
**Required**: `false`<br>
**Description**: Kafka Zookeeper Endpoint.<br>
_**Note**: This should be configured if `agent.appChecks.kafka.enabled` is set to `true`._<br>
**Options**: <br>
**Default**: <br>
**Example**:

```yaml
agent:enabled
  appChecks:
    kafka:
      zk:
        url: localhost
```

## **agent.appChecks.kafka.zk.port**
**Required**: `false`<br>
**Description**: Kafka Zookeeper Port.<br>
_**Note**: This should be configured if `agent.appChecks.kafka.enabled` is set to `true`._<br>
**Options**: `1024-65535`<br>
**Default**: <br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      zk:
        port: 2181
```

## **agent.appChecks.kafka.enableConsumerOffsets**
**Required**: `false`<br>enabled
**Description**: Whether to store consumer group config info inside Kafka itself or not. Enabling this will provide better performance.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      enableConsumerOffsets: true
```

## **agent.appChecks.kafka.enableAggregationPartitions**
**Required**: `false`<br>enabled
**Description**: Whether to enable aggregation of partitions at the topic level or not.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    kafka:
      enableAggregationPartitions: true
```

## **agent.appChecks.mysql.enabled**
**Required**: `false`<br>
**Description**: Whether to enable mysql app check.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    mysql:
      enabled: true
```

## **agent.appChecks.mysql.hostname**
**Required**: `false`<br>
**Description**: Name of the mySQL host that the agent should connect to.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    mysql:
      hostname: mysql-service-url
```

## **agent.appChecks.mysql.user**
**Required**: `false`<br>
**Description**: The username of the MySQL user that the agent will use in communicating with MySQL.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    mysql:
      user: mysql-user
```

## **agent.appChecks.mysql.password**
**Required**: `false`<br>
**Description**: The password of the MySQL user that the agent will use in communicating with MySQL.<br>
**Options**: `true|false`<br>
**Default**: `false`<br>
**Example**:

```yaml
agent:
  appChecks:
    mysql:
      password: mysql-password
```

## **agent.resources.limits.cpu**
**Required**: `false`<br>
**Description**:  The amount of cpu assigned to agent pods.<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 3      |
| medium       | 5      |
| large        | 8      |

**Example**:

```yaml
agent:
  resources:
    limits:
      cpu: 2
```

## **agent.resources.limits.memory**
**Required**: `false`<br>
**Description**:  The amount of memory assigned to agent pods.<br>
**Options**:<br>
**Default**:

| cluster-size | limits |
| ------------ | ------ |
| small        | 3Gi    |
| medium       | 6Gi    |
| large        | 10Gi   |

**Example**:

```yaml
agent:
  resources:
    limits:
      memory: 2
```

## **agent.resources.requests.cpu**
**Required**: `false`<br>
**Description**:  The amount of cpu required to schedule agent pods.<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1        |
| medium       | 3        |
| large        | 5        |

**Example**:

```yaml
agent:
  resources:
    requests:
      cpu: 2
```

## **agent.resources.requests.memory**
**Required**: `false`<br>
**Description**:  The amount of memory required to schedule agent pods.<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 1Gi      |
| medium       | 3Gi      |
| large        | 6Gi      |

**Example**:

```yaml
agent:
  resources:
    requests:
      memory: 2
```

## **agent.resources.watchdog.max_memory_usage_mb**
**Required**: `false`<br>
**Description**:  The max amount of memory the dragent process can take. Units for this value are Megabytes(mb)<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 512      |
| medium       | 1024     |
| large        | 2048     |

**Example**:

```yaml
agent:
  resources:
    watchdog:
      max_memory_usage_mb: 1024
```

## **agent.resources.watchdog.cointerface**
**Required**: `false`<br>
**Description**:  The max amount of memory cointerface is allowed to consume. Units for this value are Megabytes(mb). Cointerface is responsible for fetching k8s events from api server and also builds the relationship graph for all k8s objects. This can take up a lot of memory during startup and in large clusters.<br>
**Options**:<br>
**Default**:

| cluster-size | requests |
| ------------ | -------- |
| small        | 512      |
| medium       | 2048     |
| large        | 4096     |

**Example**:

```yaml
agent:
  resources:
    watchdog:
      cointerface: 1024
```
