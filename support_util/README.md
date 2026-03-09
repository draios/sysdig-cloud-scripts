# support-util

Utility script to collect **Kubernetes and Sysdig diagnostics** from orchestrated environments.
It speeds up data/log collection for Sysdig pods and produces a single archive you can attach to a Sysdig support ticket.

## Table of contents
1. [Overwiew](#overview)
2. [Supported Sysdig product](#supported-sysdig-product)
3. [Supported platforms](#supported-platforms)
4. [Requirements](#requirements)
5. [Usage](#usage)
6. [What is collected](#what-is-collected)
7. [Ouput](#output)
8. [Note for airgapped environments](#note-for-airgapped-environment-or-enviroment-with-limited-access-to-internet)
9. [Security and data privacy](#security-and-data-privacy)
10. [Troubleshooting](#troubleshooting)

## Overview

This script supports **only orchestrated environments** (Kubernetes and OpenShift).
It runs standard kubectl / oc read-only commands to collect cluster and Sysdig pod diagnostics, and packages them into a compressed archive.

Typical use cases:

- Before or during a Sysdig support case involving agents or security components
- Performance / sizing issues with Sysdig pods (CPU, memory, number of objects)

## Supported Sysdig product

Below the list of supported product

- Sysdig `agent` (deployed with `sysdig-deploy` chart)
- Sysdig `cluster-shield` (deployed with `sysdig-deploy` chart)
- Sysdig `node-analyzer` (deployed with `sysdig-deploy` chart), including `kspm-analyzer`, `host-scanner` and `runtime-scanner`
- Sysdig `kspm-collector` (deployed with `sysdig-deploy` chart)
- Sysdig `host-shield` (deployed with `shield` chart)

If multiple products are deployed in different namespaces, **run the script once per namespace**

## Supported platforms

The script has been tested on the following orchestrators:

- **Kubernetes**: version 1.28 and later
- **OpenShift**: version 4.12 and later

It uses **only standard** kubectl / oc commands such as:

- get (pods, deployments, daemonsets, configmaps, nodes, etc.)
- describe for selected resources
- logs for Sysdig pods

Earlier Kubernetes/OpenShift versions may work but are not explicitly tested or supported.

## Requirements

To run the script successfully, you need:

- To make sure that you installed Sysdig pods using helm, specifically our charts (https://charts.sysdig.com)

- A host where you can execute the script:
  - bastion/jump host, admin workstation, or any machine with network access to the API server

- CLI tools:
  - kubectl (for Kubernetes) or oc (for OpenShift) configured with a valid kubeconfig/context

- Permissions:
  - read-only permissions in the target namespace:
    - get, list, describe, and logs on:
      - pods, daemonsets, deployments, configmaps, namespaces
      - nodes (cluster-scoped)

- Disk Space
  - enough free space to store logs from all Sysdig pods and node stats
  - as a rule of thumb, plan additional space when the cluster has **10+ nodes**, because log size increases with the number of Sysdig pods

The script **does not modify any cluster resource**

## Usage

Basic syntax:

`./support-util.sh <namespace> [podName]`

- `namespace` (required): the namespace where the Sysdig pods are running
- `podName` (optional): a specific Sysdig pod name; when provided, the script focuses on that pod while still collecting common cluster information

Behavior:

- **Without** `podName`:
The script collects general cluster and Sysdig workload information for the given namespace.

- **With** `podName`:
The script collects all standard data plus additional information specific to the selected pod (logs, description, events, etc.).

## What is collected

For Sysdig pods in the specified namespace, the script always collects:

- Kubernetes resources (related **only** to Sysdig components)
  - ConfigMaps definitions
  - DaemonSet definitions
  - Deployment definitions

- Cluster information
  - Node list
  - Kubernetes/OpenShift version
  - Node stats (focus on **CPU** and **memory** usage) for nodes where Sysdig pods are running

- Cluster objects counts
Useful for **sizing** and **performance** analysis:
  - number of Deployments
  - number of ReplicaSets
  - number of Namespaces
  - number of ConfigMaps
  - number of Pods

- Pod-level diagnostics
  - pod describe
  - logs from Sysdig pods
  - when a `podName` is provided, detailed logs and describe for that specific pod

The exact directory structure and filenames may evolve over time, but the goal is to keep the layout stable and easy to navigate for troubleshooting.

## Output

At the end of the execution, the script generates a compressed archive.
The archive is created in the current working directory. 

## Note for airgapped environment or enviroment with limited access to Internet
If your env is airgapped or with limited access to Internet, please follow the instructions provided by the script.

## Security and data privacy

- The script performs **read-only** operations:
  - it runs `get`, `describe`, `logs`, and similar commands
  - it does **not create, update, or delete** any Kubernetes/OpenShift resources

- The generated archive may contain:
  - cluster metadata (cluster name, node names, namespaces, labels, annotations)
  - Sysdig pod logs (which might include URLs, IP addresses, resource names, and application messages)

Before sharing the archive externally:

- review your internal policies for log and configuration sharing
- if required, **sanitize or mask sensitive information** according to your company’s security and compliance rules

## Troubleshooting

Script fails with permission errors, ensure that the **requisites** are fully met.

- No Sysdig pods found
  - Confirm that the products listed in Supported Sysdig products are actually installed in the target namespace
  - Check Helm releases or your deployment manifests to identify the correct namespace.

If you still experience issues running the script, share:

- any error messages printed to the console
- the generated archive (if available), when opening or updating your Sysdig support case.
  