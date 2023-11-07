<!-- Space: TOOLS -->
<!-- Parent: Installer -->
<!-- Title: Command Line Arguments -->
<!-- Layout: plain -->

# Command line arguments explained

<br />

## Command: `deploy`

`--skip-namespace`

- installer does not deploy the `namespace.yaml` manifest.
  It expects the Namespace to exist and to match the value in `values.yaml`
  There is no validation, in case of mismatch the installer will fail

`--skip-pull-secret`

- the services expect the pull secret to exist,
  to have the expected name (`sysdigcloud-pull-secret`) and to allow access to the registry.
- if the pull secret is missing, the behaviour could be unpredictable:
  some Pods could start if they can find the image locally and if their `imagePullPolicy`
  is not `Always`
- Other Pods will fail because they can't pull the image

`--skip-serviceaccount`

- The user must provide SAs with the exact same name expected:

```
sysdig-serviceaccount.yaml:  name: sysdig
sysdig-serviceaccount.yaml:  name: node-labels-to-files
sysdig-serviceaccount.yaml:  name: sysdig-with-root
sysdig-serviceaccount.yaml:  name: sysdig-elasticsearch
sysdig-serviceaccount.yaml:  name: sysdig-cassandra
```

- One implication of this is that unless the `node-to-labels` SA is added,
  rack awareness will not work neither in Cassandra nor in ES (to be verified)
  Another implication is that if SA(s) are missing, the user will have to `describe`
  the STS because Pods will not start at all:

```
Events:
  Type     Reason            Age                   From                    Message
  ----     ------            ----                  ----                    -------
  Normal   SuccessfulCreate  2m29s                 statefulset-controller  create Claim data-sysdigcloud-cassandra-0 Pod sysdigcloud-cassandra-0 in StatefulSet sysdigcloud-cassandra success
  Warning  FailedCreate      67s (x15 over 2m29s)  statefulset-controller  create Pod sysdigcloud-cassandra-0 in StatefulSet sysdigcloud-cassandra failed error: pods "sysdigcloud-cassandra-0" is forbidden: error looking up service account benedetto/sysdig-cassandra: serviceaccount "sysdig-cassandra" not found
```

`--skip-storageclass`

- installer does not apply the StorageClass manifest.
  It expects the storageClassName specified in values.yaml to exist.

## Command: `import`

`--zookeeper-workloadname <string value>`

- This is the value that will be used for the `zookeeper` StatefulSet.
The default value is `zookeeper`, this argument must be used when the
actual name of the STS in the cluster differs

`--kafka-workloadname <value>`

- Same as above for `kafka`

`--cassandra-workloadname <value>`

- Same as above for `cassandra`

`--use-import-v2`

- This flag will use the new import logic, which will import the values from the cluster and then generate the manifests based on the imported values. Defaults to `false`, which means the old import logic will be used, unless the `--use-import-v2` flag is provided. Import V2 is supported starting from version 6.6.0, and is expected to become the default in the future.

## Command: `update-license`

Added November 2022, this is a new command.

** WARNING: THIS FEATURE requires `kubectl` to be at least version `1.20.0` **

This command performs the minimal changes and restarts to apply a new license.
Based on [this page](https://docs.sysdig.com/en/docs/administration/on-premises-deployments/upgrade-an-on-premises-license/)

This command performs the following:

- Gets a new license from either `--license` or from `--license-file name.ext`

- applies the license to `common-config` and to the relevant Secret of the following backend services:

  - `api`
  - `collector`
  - `worker`

- If `secure` and `anchore` are enabled, it also applies and restarts all Anchore services.

## Command: `image-list`

Added November 2022

This command prints to `stdout` (and optionally to a file) a list of all images in a generated stack.

It requires a `values.yaml` and it produces a list of images based on that `values.yaml`.

It does not require a live cluster, and it does not fetches any value from a live cluster, if one is accessible.

### Flags

`-f <filename>` - write the list to a file. **If the file exists, it is overwritten**

### Example

```
./installer/out/installer-darwin-amd64 image-list
I1118 18:48:44.643520   97065 main.go:64] Installer version
I1118 18:48:44.646391   97065 values.go:122] using namespace sysdig from values.yaml
I1118 18:48:44.660236   97065 imagelist.go:44] installerVersion:     darwin amd64 gc
I1118 18:48:44.660263   97065 imagelist.go:13] generating manifests
I1118 18:48:44.722172   97065 validate.go:1255] skipping Kubernetes version validation for PostgreSQL because HA is not enabled
I1118 18:48:44.723158   97065 generate.go:171] validation stage:generate passed
I1118 18:49:00.625921   97065 generate.go:234] Generating kubernetes manifests
I1118 18:49:00.642116   97065 generate.go:253] Generating kubernetes manifests for dependencies
I1118 18:49:00.987615   97065 imagelist.go:20] extracting images from generated manifests
I1118 18:49:01.147089   97065 imagelist.go:23] writing images list to file image_list.txt
I1118 18:49:01.147276   97065 imagelist.go:30] found 72 images in the generated manifests
quay.io/sysdig/activity-audit-api:6.0.0.12431
quay.io/sysdig/certman-janitor:6.0.0.12431
quay.io/sysdig/nginx:6.0.0.12431
quay.io/sysdig/anchore:0.8.1-49
quay.io/sysdig/postgres:12.10.0.0
quay.io/sysdig/cp-kafka-6:0.2.1
quay.io/sysdig/kube-rbac-proxy:v0.8.0
quay.io/sysdig/secure-onboarding-api:6.0.0.12431
quay.io/sysdig/nats-streaming-init:0.22.0.8
quay.io/sysdig/ui-monitor-nginx:6.0.0.12431
quay.io/sysdig/sysdig-worker:6.0.0.12431
quay.io/sysdig/profiling-api:6.0.0.12431
quay.io/sysdig/scanning-retention-mgr:6.0.0.12431
quay.io/sysdig/sysdig-api:6.0.0.12431
quay.io/sysdig/helm-renderer:1.0.677
quay.io/sysdig/cp-zookeeper-6:0.4.0
quay.io/sysdig/redis-sentinel-6:1.0.1
quay.io/sysdig/activity-audit-janitor:6.0.0.12431
quay.io/sysdig/secure-todo-worker:6.0.0.12431
quay.io/sysdig/reporting-init:6.0.0.12431
quay.io/sysdig/certman:6.0.0.12431
quay.io/sysdig/sysdig-meerkat-collector:6.0.0.12431
quay.io/sysdig/policies:6.0.0.12431
quay.io/sysdig/profiling-worker:6.0.0.12431
quay.io/sysdig/cloudsec-api:6.0.0.12431
quay.io/sysdig/compliance-api:6.0.0.12431
quay.io/sysdig/elasticsearch-tools:0.0.35
quay.io/sysdig/events-forwarder:6.0.0.12431
quay.io/sysdig/ingress-default-backend:1.5
docker.io/sysdig/falco_rules_installer:latest
quay.io/sysdig/events-api:6.0.0.12431
quay.io/sysdig/events-forwarder-api:6.0.0.12431
quay.io/sysdig/promqlator:0.99.0-master.2022-10-03T12-41-14Z.2f800e101b
quay.io/sysdig/ui-secure-nginx:6.0.0.12431
quay.io/sysdig/reporting-worker:6.0.0.12431
quay.io/sysdig/scanning-ve-janitor:6.0.0.12431
quay.io/sysdig/rapid-response-janitor:6.0.0.12431
quay.io/sysdig/compliance-worker:6.0.0.12431
quay.io/sysdig/events-janitor:6.0.0.12431
quay.io/sysdig/events-dispatcher:6.0.0.12431
quay.io/sysdig/haproxy-ingress:1.1.5-v0.10
quay.io/sysdig/sysdig-meerkat-api:6.0.0.12431
quay.io/sysdig/metadata-service-operator:1.0.1.23
quay.io/sysdig/netsec:6.0.0.12431
quay.io/sysdig/nats-streaming:0.22.0.8
quay.io/sysdig/nats-exporter:0.9.0.2
quay.io/sysdig/secure-prometheus:2.17.2
quay.io/sysdig/opensearch-1:0.0.16
quay.io/sysdig/events-gatherer:6.0.0.12431
quay.io/sysdig/reporting-api:6.0.0.12431
quay.io/sysdig/promchap:0.99.0-master.2022-11-18T13-46-40Z.d6b3d10f83
quay.io/sysdig/redis-6:1.0.1
quay.io/sysdig/ui-admin-nginx:6.0.0.12431
quay.io/sysdig/admission-controller-api-pg-migrate:6.0.0.12431
quay.io/sysdig/admission-controller-api:6.0.0.12431
quay.io/sysdig/scanning:6.0.0.12431
quay.io/sysdig/sysdig-alert-notifier:6.0.0.12431
quay.io/sysdig/cassandra-3:0.0.36
quay.io/sysdig/metadata-service-server:1.10.63
quay.io/sysdig/rapid-response-connector:6.0.0.12431
quay.io/sysdig/secure-todo-api:6.0.0.12431
quay.io/sysdig/api-docs:6.0.0.12431
quay.io/sysdig/cloudsec-worker:6.0.0.12431
quay.io/sysdig/sysdig-collector:6.0.0.12431
quay.io/sysdig/events-ingestion:6.0.0.12431
quay.io/sysdig/rsyslog:8.2102.0.4
quay.io/sysdig/sysdig-meerkat-aggregator:6.0.0.12431
quay.io/sysdig/secure-todo-janitor:6.0.0.12431
quay.io/sysdig/sysdig-alert-manager:6.0.0.12431
quay.io/sysdig/redis-exporter-1:1.0.9
quay.io/sysdig/ui-inspect-nginx:6.0.0.12431
```

## Command: `diff`

Will perform a diff between the platform objects in a running k8s cluster, and the generated manifests based on some values.

`--write-diff`

- Will write the diff on the filesystem organized in subfolders, rather than printing it to the stdout.

`--out-diff-dir`

- Allows you to specify a custom path for the diff files being written on the filesystem. Will be used only if also `--write-diff` is provided. If not set will use a temporary directory.

`--cleanup`

- If set, will attempt to automatically delete any generated diff files on the filesystem if the directory used to store the diff files already exists. Requires both `--write-diff` and `--out-diff-dir` to be set.

`--secure`

- applies some filters to the produced diff in order to avoid printing sensitive informations. This is useful if you need to share diffs to user who shouldn't have access to credentials.

`--summary`

- Only prints a summary of the diff errors.

Diff command also has options inherited from the generate command options. See **generate** command section.

### Sub-Command: secure-diff [DEPRECATED]

Performs a diff not showing sensitive information.
This subcommand is DEPRECATED and will be removed starting from version 6.7.0, you can have the same effect with the diff command and the flag `--secure`.

## Command: `generate`

`--manifest-directory`

- Set the location where the installer will write the genearted manifests.

`--skip-generate`

- Skips generating Kubernetes manifests and attempts to diff whatever is in the manifests directory. Manifest directory can be specified using `--manifest-directory <dir>` flag.

`--skip-import`

- Skips the import phase, which would try to import values from a running cluster.

`--skip-validation`

- Skips validation checks.

`--ignore-kubeconfig-errors`

- This will ignore all errors from trying to parse kubeconfig file.

`--preserve-templates`

- Preserve directory installer templates are extracted to, this should only be used for debugging purposes

`--k8s-server-version`

- Sets the `kubernetesServerVersion` within values.
