# Sysdig Log Collector (SLC)

A single Bash script that collects a **Sysdig support bundle** from a Kubernetes
cluster and (optionally) uploads it to Sysdig Support. It works for **Agent /
Shield** on any cluster (SaaS or on-prem) and for the **on-prem Platform**
backend.

It is **read-only** on the cluster — it never creates, modifies, or deletes
cluster resources. It only writes a local archive, and logs everything it does
to the bundle's `activity.log`.

## Requirements

- `bash` 3.2+ (works with the default macOS bash and any Linux bash)
- `kubectl` (or `oc` for OpenShift) on your `PATH`, configured to reach the cluster
- Read access to the target namespace(s)

## Download & install

Download the script and install it onto your `PATH`:

```bash
# 1. Download the script
curl -fsSL "<download-url>" -o sysdig-log-collector

# 2. Install onto your PATH
sudo install -m 0555 sysdig-log-collector /usr/local/bin/sysdig-log-collector

# 3. Run it
sysdig-log-collector --help
```

Prefer not to install system-wide? Run it straight from the download directory,
or install without `sudo` to a `PATH` directory you own:

```bash
# Run in place from the download directory
chmod +x sysdig-log-collector
./sysdig-log-collector --help

# Or install to a user PATH directory (no sudo)
install -m 0555 sysdig-log-collector ~/.local/bin/
```

**Notes**
- The filename/extension doesn't matter to Bash; the script has no extension by
  design.
- **Windows users:** save with **Unix (LF) line endings**. CRLF line endings will
  break the script. (Most users collecting Kubernetes bundles run on Linux/macOS.)
- The examples below use placeholders like `<sysdig-agent>` and `<sysdigcloud>` —
  replace them with your actual namespace names.

## Upgrading

To upgrade, re-download the latest script and re-run the install — it overwrites
the existing copy:

```bash
curl -fsSL "<download-url>" -o sysdig-log-collector
sudo install -m 0555 sysdig-log-collector /usr/local/bin/sysdig-log-collector
```

## Quick start

```bash
# Agent bundle — every Sysdig pod in the namespace (most common)
sysdig-log-collector collect agent -n <sysdig-agent>

# On-prem Platform bundle — everything in the platform namespace
sysdig-log-collector collect platform -n <sysdigcloud>

# Interactive, menu-driven (prompts for everything)
sysdig-log-collector -i
```

The archive is written to the current directory unless you pass `-o <dir>`.

**Tip:** enable shell tab-completion (bash/zsh auto-detected) for command, flag,
and live-namespace completion, then restart your shell:

```bash
sysdig-log-collector autocomplete enable
```

Disable anytime with `sysdig-log-collector autocomplete disable`.

## Choosing what to collect (scope)

Pick **one** scope per run; the default is "everything in the namespace".

| You want… | Use |
|---|---|
| All Sysdig pods in a namespace | *(default)* `-n <ns>` |
| Only certain component types | `--components <list>` |
| Only specific pods | `--pods <list>` |
| Several namespaces at once (agent only) | `--namespaces <entries>` |

Component names depend on which chart is installed: the **Shield** chart exposes
`shield` and `cluster-shield`; the **sysdig-deploy** chart exposes `agent`,
`node-analyzer`, `kspm-collector`, and more; the standalone **agent** sub-chart
exposes `agent`. Discover the exact names with `list` (below).

```bash
# Shield chart
sysdig-log-collector collect agent -n <sysdig-agent> --components=cluster-shield

# sysdig-deploy chart
sysdig-log-collector collect agent -n <sysdig-agent> --components=node-analyzer,kspm-collector

# agent sub-chart — specific pods
sysdig-log-collector collect agent -n <sysdig-agent> --pods=sysdig-agent-abcde,sysdig-agent-fghij
```

For long lists, put one name per line in a file (no blank lines) and use
`--from-file` with `--pods` or `--components`:

```bash
sysdig-log-collector collect agent -n <sysdig-agent> --pods --from-file=pods.txt
```

## Discover names first: `list`

```bash
sysdig-log-collector list agent components -n <sysdig-agent>
sysdig-log-collector list agent pods -n <sysdig-agent>
sysdig-log-collector list platform components -n <sysdigcloud>
```

## Uploading to Sysdig Support

Sysdig Support provides a **presigned S3 URL**. Always wrap it in **single quotes**
(it contains `&` and `=`).

```bash
# Collect and upload in one step
sysdig-log-collector collect agent -n <sysdig-agent> --url='https://...amazonaws.com/...x-id=PutObject'

# Upload an archive you already have
sysdig-log-collector upload -f bundle.tgz --url='https://...x-id=PutObject'

# Verify a URL without uploading (presigned URLs expire)
sysdig-log-collector upload -f bundle.tgz --url='https://...PutObject' --dry-run
```

Add `--no-save` to delete the local copy after a successful upload.

## Common options

| Flag | Meaning |
|---|---|
| `-n, --namespace <ns>` | Target namespace |
| `-c, --context <name>` | kubectl context (defaults to current-context) |
| `-o, --output-dir <path>` | Where to write the archive (default: current dir) |
| `-j, --max-jobs <N>` | Parallel collector workers, 1–16 (default 4) |
| `-u, --url <url>` | Presigned S3 PUT URL to upload to |

Platform-only: `--healthcheck` (skip per-container logs), `--since=<dur>` (log
window), `--api-key` / `--secure-api-key` (optional API data), `--local-api`
(reach the API via port-forward).

Run `sysdig-log-collector <command> --help` for the full flag list.

## Version

Print the Sysdig Log Collector version (useful when reporting an issue to Sysdig Support):

```bash
sysdig-log-collector version
# Sysdig Log Collector version 1.0.1
```

The same version is shown under the banner in interactive mode (`-i`) and
recorded in every bundle's `activity.log` header.

## What gets collected (review before sharing)

A bundle contains operational data from your cluster — pod **logs**, `describe`
output, Sysdig **manifests/configmaps**, node info, and (for platform) datastore
telemetry and optional API data. It does **not** include your API keys (entered
hidden, validated, and wiped after the run). Everything the tool did is recorded
in the bundle's `activity.log`. Review the archive if you have data-handling
requirements before sending it to Support.

## Safety

- No Kubernetes resources are created, modified, or deleted.
- `kubectl`/`oc` access is read-only — `get`, `describe`, `logs`, `cp`, `exec` —
  with one exception, inside the agent pods: during **agent log collection**,
  `exec` runs `tar` to create a temporary archive of `/opt/draios/logs`
  (written to `/tmp/draios-logs.tgz`, or `/opt/draios/draios-logs.tgz` as a
  fallback — the agent's own writable volume), copies it out, then removes it
  with `rm -f`. This touches only an ephemeral file inside the pod, never a
  Kubernetes resource.
- Sysdig API calls are GET-only against the platform's own endpoints.
- Before archiving the bundle, all sensitive data (access keys, datastore
  passwords, bearer tokens, and embedded credentials in connection URLs) are
  masked in place as `<redacted>`. This is a best-effort safeguard, not a
  guarantee; kindly review the archive before sharing externally.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `no Sysdig components found in namespace` | Wrong namespace — confirm with `list agent components -n <ns>`. |
| `unknown component '<x>'` | Not a valid bucket; the error prints the accepted list. |
| `invalid --url` | URL must start with `https://`, contain `.amazonaws.com`, include `X-Amz-Signature=`, end with `x-id=PutObject` — and be single-quoted. |
| `presigned URL expired` | Request a fresh URL from Sysdig Support. |
| Collection is slow / heavy | Lower `-j` (e.g. `-j 2`); for platform add `--healthcheck` and/or `--since=1h`. |
| `<pod>: file-based logs unavailable (…), fell back to kubectl logs — stdout logs only for this pod` | The in-pod `tar` step (Tier 0) couldn't run — the exec was refused — so only container stdout was collected instead of the full on-disk `draios.log`. The Sysdig image ships `tar`, so the cause is one of:<br>• **Missing RBAC** — grant `create` on `pods/exec` in the Role/ClusterRole bound to the collector's identity (a namespace Role suffices), or run from a context that already has exec.<br>• **Admission controller** (Kyverno / OPA-Gatekeeper) blocking exec — add an exec exception for the namespace.<br>The `Tier 0: cannot exec …` line in `activity.log` has the raw error, which tells you which. |
| `Error: no logs collected for <pod> (all 3 tiers failed — …)` | The stdout fallback (Tier 3) also produced nothing. The `Reason:` in `activity.log` says which:<br>• The pod **isn't running** — confirm with `kubectl get pod <pod> -n <ns>`.<br>• Missing **`get` on `pods`/`pods/log`** — grant it on the Role/ClusterRole bound to the collector's identity.<br>• The pod has written nothing to stdout. |
| `bad interpreter` / `\r: command not found` | The file has Windows (CRLF) line endings — re-save as LF, or run `sed -i 's/\r$//' sysdig-log-collector`. |
