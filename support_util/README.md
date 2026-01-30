# support-util

This script supports only orchestrated environment, speeding up the data/log collection for Sysdig pods.
Data collection for Sysdig pods will always include:
- getting `ConfigMap`
- getting `DaemonSet` definition
- getting `Deployment` definition
- getting Kubernetes version
- getting nodes
- getting stats for nodes, especially CPU and Memory, where Sysdig pods are running
- a count of cluster objects, like:
    - Deployments
    - ReplicaSets
    - Namespaces
    - ConfigMaps
    - Pods

that we may need if you're having sizing issue with clusterShield.

# Supported Sysdig product

Below the list of supported product

- Sysdig `agent` (deployed with `sysdig-deploy` chart)
- Sysdig `cluster-shield` (deployed with `sysdig-deploy` chart)
- Sysdig `node-analyzer` (deployed with `sysdig-deploy` chart), `kspm-analyzer`, `host-scanner` and `runtime-scanner`
- Sysdig `kspm-collector` (deployed with `sysdig-deploy` chart)
- Sysdig `host-shield` (deployed with `shield` chart)

# Supported k8s version
The script uses `kubectl` or `oc` standard commands, like `get pod`, `get deployment` and so on.
Environments used for the test are Kubernetes v1.28 and greater and OpenShift v4.12 and greater.

# Note for airgapped environment or enviroment with limited access to Internet
If your env is airgapped or with limited access to Internet, please follow the instructions provided by the script.

# Usage

The script takes in input two parameters:
- `namespace` (mandatory)
- `podName` (optional)

If you do not pass the `podName` parameter, the script will collect what is described at the beginning of this README. If `podName` is passed, the script will collect the information related to the specific pod, plus what is included in the list of data collection.

At the end of the execution, please remove the archive file and the directory created by the script.

**WARNING - If your cluster have a good amount of nodes, 10 or more, please make sure to have a good amount of space available in the host where you'll run the script since log size, and their number, can vary based on the number of sysdig pod running in your cluster**
