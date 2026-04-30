# get_support_bundle.sh

## NAME

`get_support_bundle.sh` — collect a Sysdig on-premises Kubernetes support bundle

## SYNOPSIS

```
get_support_bundle.sh [-a <API_KEY>] [-c <CONTEXT>] [-d] [-l <LABELS>]
                      [-la] [-n <NAMESPACE>] [-s <TIMEFRAME>]
                      [-sa <SECURE_API_KEY>] [--skip-logs]
                      [--max-jobs <N>] [-h]
```

## DESCRIPTION

`get_support_bundle.sh` collects diagnostic data from a Sysdig on-premises
Kubernetes deployment and packages it into a timestamped `.tgz` archive for
support analysis. It gathers pod logs, container support files, cluster state,
node information, resource manifests, Cassandra and Elasticsearch diagnostics,
storage utilization, and — when API credentials are supplied — license data,
settings, metrics, and scanning results.

The script targets a single Kubernetes namespace and uses the currently active
`kubectl` context unless overridden. It requires `kubectl` and `jq` to be
present on the local machine and assumes sufficient RBAC permissions to read
pods, nodes, configmaps, and execute into containers in the target namespace.

## OPTIONS

```
-a, --api-key <API_KEY>
    Superuser API key for advanced data collection. When supplied, the script
    validates the key and collects license info, agent connections, storage,
    stream snap, snapshot, plan, data retention, user, team, SSO, alert
    settings, and metrics. Also collects version-specific settings
    (meerkatSettings for v6/v7; fastPathSettings and indexSettings for v3-v5).

-c, --context <CONTEXT>
    kubectl context to use. Defaults to the currently active context.

-d, --debug
    Enable bash debug output (set -x). Useful for troubleshooting failures
    or auditing exactly which kubectl commands are executed.

-l, --labels <LABELS>
    Restrict pod log and description collection to pods matching the given
    Sysdig role label(s). Accepts a comma-separated list of role values
    (e.g., api,collector,worker). Defaults to all pods in the namespace.

-la, --local-api
    Use kubectl port-forward to reach the Sysdig API instead of resolving
    the API URL from the cluster configmap. Required in environments where
    the API FQDN is not reachable from the machine running this script.

-n, --namespace <NAMESPACE>
    Kubernetes namespace containing the Sysdig deployment.
    Default: sysdig

-s, --since <TIMEFRAME>
    Limit kubectl log collection to the specified time window. Accepts any
    value valid for kubectl --since (e.g., 1h, 30m, 2d). Defaults to full
    available log history.

-sa, --secure-api-key <SECURE_API_KEY>
    Secure module Superuser API key. When supplied, checks whether Scanning
    V1 and/or V2 are enabled and collects the corresponding results.

--skip-logs
    Skip all pod log and container support file collection. Useful for a
    fast cluster-state-only capture when logs are not needed.
    Default: false

--max-jobs <N>
    Maximum number of concurrent background collection jobs. Controls the
    degree of parallelism. Can also be set via the MAX_JOBS environment
    variable. See PARALLEL PROCESSING below.
    Default: 6

-h, --help
    Print usage information and exit.
```

## ENVIRONMENT

```
MAX_JOBS
    Sets the default maximum concurrent jobs. Overridden by --max-jobs if
    both are specified. Example: MAX_JOBS=10 ./get_support_bundle.sh
```

## OUTPUT

The script creates a tarball in the current working directory named:

```
<unix_epoch>_sysdig_cloud_support_bundle.tgz
```

The archive contains a single top-level directory with the following structure:

```
sysdigcloud-support-bundle-XXXX/
├── backend_version.txt          # Image tag of sysdigcloud-api deployment
├── config.yaml                  # sysdigcloud-config ConfigMap (passwords redacted)
├── container_density.txt        # Pod and container counts per node
├── describe_node_output.txt     # kubectl describe nodes output
├── pv_output.log                # PersistentVolumes matching 'sysdig'
├── pvc_output.log               # PersistentVolumeClaims in namespace
├── sc_output.log                # StorageClasses
├── kubectl-cluster-dump/        # kubectl cluster-info dump output
├── nodes/
│   └── <node-name>-kubectl.json
├── pod_logs/
│   └── <pod-name>/
│       ├── <container>-kubectl-logs.txt
│       └── <container>-support-files.tgz  # /logs/, /opt/draios/, /var/log/*, etc.
├── <pod-name>/
│   └── kubectl-describe.json    # One directory per pod with its JSON spec
├── cassandra/
│   └── <pod-name>/
│       ├── nodetool_info.log
│       ├── nodetool_status.log
│       ├── nodetool_cfstats.log
│       ├── nodetool_cfhistograms.log
│       ├── nodetool_compactionstats.log
│       ├── nodetool_getcompactionthroughput.log
│       ├── nodetool_proxyhistograms.log
│       ├── nodetool_tpstats.log
│       └── cassandra_storage.log
├── elasticsearch/
│   └── <pod-name>/
│       ├── elasticsearch_health.log
│       ├── elasticsearch_indices.log
│       ├── elasticsearch_nodes.log
│       ├── elasticsearch_index_allocation.log
│       ├── elasticsearch_index_versions.log
│       ├── elasticsearch_storage.log
│       ├── elasticsearch_node_pem_expiration.log
│       ├── elasticsearch_admin_pem_expiration.log
│       └── elasticsearch_root_ca_pem_expiration.log
├── neo4j/
│   └── <pod-name>/
│       ├── cypher_show_servers.txt
│       └── cypher_show_databases.txt
├── <postgresql|mysql|kafka|zookeeper>/
│   └── <pod-name>/
│       └── <db>_storage.log
├── <svc|deployment|sts|pvc|daemonset|ingress|replicaset|
│    networkpolicy|cronjob|configmap|pdb|routes>/
│   └── <name>-kubectl.json
│
│   # Present only when --api-key is supplied:
├── license.json
├── agents_connected.json
├── storage_settings.json
├── streamSnap_settings.json
├── snapshot_settings.json
├── plan_settings.json
├── dataRetention_settings.json
├── users.json
├── teams.json
├── sso_settings.json
├── alerts.json
├── meerkat_settings.json        # v6/v7 only
├── fastPath_settings.json       # v3/v4/v5 only
├── index_settings.json          # v3/v4/v5 only
├── metrics/
│   ├── agent_version_metric_limits.json
│   ├── syscall.count_host.hostName.json
│   ├── syscall.count_proc.name.json
│   ├── dragent.analyzer.sr_host.hostName.json
│   ├── container.count_host.hostName.json
│   ├── dragent.analyzer.n_drops_buffer_host.hostName.json
│   └── dragent.analyzer.n_evts_host.hostName.json
│
│   # Present only when --secure-api-key is supplied and scanning is enabled:
└── scanning/
    ├── scanningv1.txt            # ScanningV1 results (if enabled)
    └── scanningv2.txt            # ScanningV2 results (if enabled)
```

## EXAMPLES

Collect a bundle from the default `sysdig` namespace:
```bash
./get_support_bundle.sh
```

Specify a namespace and kubectl context:
```bash
./get_support_bundle.sh -n sysdigcloud -c prod-us-east-1
```

Collect only the last two hours of logs:
```bash
./get_support_bundle.sh -n sysdigcloud -s 2h
```

Collect with API data from a backend v6/v7 cluster:
```bash
./get_support_bundle.sh -n sysdigcloud -a <SUPERUSER_API_KEY>
```

Collect with both Monitor and Secure API keys:
```bash
./get_support_bundle.sh -n sysdigcloud \
  -a <SUPERUSER_API_KEY> \
  -sa <SECURE_SUPERUSER_API_KEY>
```

Skip log collection for a fast cluster-state snapshot:
```bash
./get_support_bundle.sh -n sysdigcloud --skip-logs
```

Restrict collection to specific pod roles:
```bash
./get_support_bundle.sh -n sysdigcloud -l api,collector,worker
```

Run serially (useful for debugging or rate-limited clusters):
```bash
./get_support_bundle.sh -n sysdigcloud --max-jobs 1
```

## PARALLEL PROCESSING

This version of the script is a refactored, parallelized edition of the
original `get_support_bundle.sh`. The operational logic — every kubectl
command, curl call, file path, and output format — is identical to the
original. The only change is that independent collection tasks that previously
ran serially are now dispatched as concurrent background jobs.

### What runs in parallel

| Phase | Parallelized unit |
|---|---|
| Pod log and support file collection | One background job per container |
| Node manifest collection | One background job per node |
| Resource manifest collection | One background job per resource type |
| Cassandra stats, Elasticsearch stats, all DB storage checks | One background job per task |
| `kubectl cluster-info dump` | Runs in background alongside log collection |

Discovery steps (listing pods, nodes, container names) and directory creation
remain serial to avoid race conditions.

### Concurrency control

Three helper functions implement the job control system:

- **`run_bg <jobname> <cmd>`** — forks `cmd` into a background subshell,
  redirecting stdout and stderr to temporary files so output does not
  interleave on the terminal. Registers the PID for later collection.

- **`throttle`** — called after each `run_bg` to block until the number of
  running background jobs drops below `MAX_JOBS`. Uses `wait -n` on
  Bash 4.3+ for efficient wake-up; falls back to `sleep 0.1` polling on
  older Bash (including macOS default Bash 3.2).

- **`wait_all`** — waits for all registered background PIDs to finish,
  emits a warning to stderr for any that exit non-zero, resets the PID
  list, and removes the temporary output files. Called at the end of each
  parallel phase to ensure completion before the next phase begins.

### Performance

On a representative cluster (~40 pods, ~120 containers):

| Mode | Wall time | Bundle size |
|---|---|---|
| Original serial script | ~10m 36s | 11 MB |
| This script (MAX_JOBS=6) | ~3m 32s | 11 MB |

Higher `--max-jobs` values yield diminishing returns once network I/O to the
cluster becomes the bottleneck. The default of 6 is conservative and suitable
for most production clusters. Reduce to 3–4 if the API server shows signs of
rate limiting (429 responses or increased latency during collection).
