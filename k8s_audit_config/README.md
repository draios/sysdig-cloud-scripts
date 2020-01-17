# Introduction

This page describes how to configure K8s audit Logging, routing audit events to the Sysdig Agent. The configuration consists of two parts:

* Enabling K8s audit functionality in your K8s cluster.
* Configuring the K8s cluster to route K8s audit events to the sysdig agent.

In all cases, you should first install a Sysdig Agent to your cluster, following the [Agent Installation Instructions for Kubernetes](https://docs.sysdig.com/en/agent-installation.html) to create a Sysdig Agent service account, secret, configmap, service, and daemonset.

These instructions cover the following K8s distributions:

* Openshift: 3.11, 4.2
* Minishift: When using openshift 3.11
* Kops
* GKE
* EKS
* RKE
* IKS
* Minikube

For some distributions, the set of audit events may be limited, in which case that is noted.

Support for K8s audit events has changed rapidly between K8s versions. Routing of audit events can be implemented by one of the following:

* Webhook backend: K8s >= 1.11.
* Dynamic backend: K8s >= 1.13.

In cases where a distribution is tied to a specific K8s version, documention sets up a backend for the appropriate version. In cases where a distribution supports both versions 1.11/12 or 1.13, instructions prefer dynamic backends over webhook backends when possible.

These instructions assume that the K8s cluster has *no* audit configuration or logging in place, and are adding configuration to route audit log messages only to the sysdig agent.

There is a [script](#Script-to-automate-configuration-changes) that automates many of these steps that is suitable for proof-of-concept/non-production environments. In any case, we recommend reading the step-by-step instructions carefully before continuing.

## Openshift 3.11

Openshift 3.11 only supports webhook backends (described as "Advanced Audit" in the [Openshift](https://docs.openshift.com/container-platform/3.11/install_config/master_node_configuration.html#master-node-config-advanced-audit) Documentation). To configure a webhook backend, perform the following steps:

1. Copy the provided [audit-policy.yaml](./audit-policy.yaml) file to the k8s api master node into the directory `/etc/origin/master`. This directory is mounted into the kube api server container at `/etc/origin/master`.
1. Follow the instructions described in [Creating a webhook configuration file](#Creating a webhook configuration file)] to create a `webhook-config.yaml` file and copy it to the k8s api master node into the directory `/etc/origin/master`.
1. On the k8s api master node, modify the master configuration by adding the following to your `/etc/origin/master/master-config.yaml` file, replacing any existing `auditConfig:` entry.

    ```yaml
    auditConfig:
      enabled: true
      maximumFileSizeMegabytes: 10
      maximumRetainedFiles: 1
      auditFilePath: "/etc/origin/master/k8s_audit_events.log"
      logFormat: json
      webHookMode: "batch"
      webHookKubeConfig: /etc/origin/master/webhook-config.yaml
      policyFile: /etc/origin/master/audit-policy.yaml
    ```

    One way to do this is to use `oc ex config patch`. Assuming the above content were in a file `audit-patch.yaml`, and you had copied `/etc/origin/master/master-config.yaml` to `/tmp/master-config.yaml.original`, you could run `oc ex config patch /tmp/master-config.yaml.original -p "$(cat audit-patch.yaml)" > /etc/origin/master/master-config.yaml`.

1. Restart the apiserver by running the following on the k8s api master node. Once restarted, the K8s api server will route K8s audit events to the agent's service.

    ```bash
    # sudo /usr/local/bin/master-restart api
    # sudo /usr/local/bin/master-restart controllers
    ```

## Minishift 3.11

Minishift 3.11 also supports webhook backends, but the way minishift launches the k8s api server differs from the way openshift launches the k8s api server, meaning that you can not use the documented instructions above. Instead, you must modify the command line arguments for the kube api server to enable the webhook backend.

1. Copy the provided [audit-policy.yaml](./audit-policy.yaml) file to the minishift VM into the directory `/var/lib/minishift/base/kube-apiserver/`. This directory is mounted into the kube api server container at `/etc/origin/master`.
1. Follow the instructions described in [Creating a webhook configuration file](#Creating a webhook configuration file)] to create a `webhook-config.yaml` file and copy it to the minishift VM into the directory `/var/lib/minishift/base/kube-apiserver/`.
1. Modify the master configuration by adding the following to `/var/lib/minishift/base/kube-apiserver/master-config.yaml` on the minishift VM, merging/updating as required. *Note*: master-config.yaml also exists in other directories such as `/var/lib/minishift/base/openshift-apiserver`, `/var/lib/minishift/base/openshift-controller-manager/`. You should modify the one in `kube-apiserver`:

    ```yaml
    kubernetesMasterConfig:
      apiServerArguments:
      audit-log-maxbackup:
      - "1"
      audit-log-maxsize:
      - "10"
      audit-log-path:
      - /etc/origin/master/k8s_audit_events.log
      audit-policy-file:
      - /etc/origin/master/audit-policy.yaml
      audit-webhook-batch-max-wait:
      - 5s
      audit-webhook-config-file:
      - /etc/origin/master/webhook-config.yaml
      audit-webhook-mode:
      - batch
    ```

1. Restart the apiserver via the following. Once restarted, Once restarted, the K8s api server will route K8s audit events to the agent's service.

    ```bash
    (For minishift)
    # minishift openshift restart
    ```

## Openshift 4.2

Openshift 4.2 by default enables K8s api server logs and makes them available on each master node at the path `/var/log/kube-apiserver/audit.log`. However, the api server is not configured by default with the ability to create dynamic backends. You must first enable the ability to create dynamic backends by changing the apiserver configuration. Once dynamic backends are enabled, you can then create audit sinks to route audit events to the sysdig agent.

1. Run the following to update the apiserver configuration. After running the command, wait for the api server to restart with the updated configuration.

```
oc patch kubeapiserver cluster --type=merge -p '{"spec":{"unsupportedConfigOverrides":{"apiServerArguments":{"audit-dynamic-configuration":["true"],"feature-gates":["DynamicAuditing=true"],"runtime-config":["auditregistration.k8s.io/v1alpha1=true"]}}}}'
```

1. Follow the instructions described in [Create an Audit Sink Pointing to the Agent Service](#Create an Audit Sink Pointing to the Agent Service)] to create and apply a dynamic audit sink. Once the dynamic audit sink is created, it will route K8s audit events to the agent's service.

## Kops

These instructions modify the cluster configuration using `kops set`, update the configuration using `kops update`, and then perform a rolling update using `kops rolling-update`. It configures a webhook backend, as the latest released version of kops (1.15) does not yet support configuring dynamic backends. A fix for kops is merged in https://github.com/kubernetes/kops/pull/7424 but is not yet part of any kops release.

1. Follow the instructions described in [Creating a webhook configuration file](#Creating a webhook configuration file)] to create a `webhook-config.yaml` file and save it locally.
1. Get the current cluster configuration and save it to a file:

```
kops get cluster <your cluster name> -o yaml > cluster-current.yaml
```

1. Edit cluster.yaml to add/modify `fileAssets` and `kubeAPIServer` sections as follows. This ensures that `webhook-config.yaml` is available on each master node at `/var/lib/k8s_audit` and that the kube-apiserver process is run with the required arguments to enable the webhook backend.

```
apiVersion: kops.k8s.io/v1alpha2
kind: Cluster
spec:
  ...
  fileAssets:
    - name: webhook-config
      path: /var/lib/k8s_audit/webhook-config.yaml
      roles: [Master]
      content: |
        <contents of webhook-config.yaml go here>
    - name: audit-policy
      path: /var/lib/k8s_audit/audit-policy.yaml
      roles: [Master]
      content: |
        <contents of audit-policy.yaml go here>
  ...
  kubeAPIServer:
    auditLogPath: /var/lib/k8s_audit/audit.log
    auditLogMaxBackups: 1
    auditLogMaxSize: 10
    auditWebhookBatchMaxWait: 5s
    auditPolicyFile: /var/lib/k8s_audit/audit-policy.yaml
    auditWebhookConfigFile: /var/lib/k8s_audit/webhook-config.yaml
  ...
```

A simple way to do this using `yq` would be with the following script:

```
cat <<EOF > merge.yaml
spec:
  fileAssets:
    - name: webhook-config
      path: /var/lib/k8s_audit/webhook-config.yaml
      roles: [Master]
      content: |
$(cat webhook-config.yaml | sed -e 's/^/        /')
    - name: audit-policy
      path: /var/lib/k8s_audit/audit-policy.yaml
      roles: [Master]
      content: |
$(cat audit-policy.yaml | sed -e 's/^/        /')
  kubeAPIServer:
    auditLogPath: /var/lib/k8s_audit/audit.log
    auditLogMaxBackups: 1
    auditLogMaxSize: 10
    auditWebhookBatchMaxWait: 5s
    auditPolicyFile: /var/lib/k8s_audit/audit-policy.yaml
    auditWebhookConfigFile: /var/lib/k8s_audit/webhook-config.yaml
EOF

yq m -a cluster-current.yaml merge.yaml > cluster.yaml
```

1. Configure kops with the new cluster configuration:

```
kops replace -f cluster.yaml
```

1. Update the cluster configuration to prepare changes to the cluster

```
kops update cluster <your cluster name> --yes
```

1. Perform a rolling update to redeploy the master nodes with the new files and apiserver configuration:

```
kops rolling-update cluster --yes
```

## GKE

(These instructions assume you already have created a cluster and have configured the `gcloud` and `kubectl` command line programs to interact with the cluster)

GKE already provides [K8s Audit Logs](https://cloud.google.com/kubernetes-engine/docs/how-to/audit-logging), but the logs are exposed using stackdriver and are in a different format than the native format used by kubernetes. To make it easier to use k8s audit logs in gke, we've written a [bridge program](https://github.com/sysdiglabs/stackdriver-webhook-bridge) that reads audit logs from stackdriver, reformats them to match the k8s native format, and sends the logs to a configurable webhook.

1. Create a google cloud (not k8s) service account and key that has the ability to read logs:

```
$ gcloud iam service-accounts create swb-logs-reader --description "Service account used by stackdriver-webhook-bridge" --display-name "stackdriver-webhook-bridge logs reader"
$ gcloud projects add-iam-policy-binding <your gce project id> --member serviceAccount:swb-logs-reader@<your gce project id>.iam.gserviceaccount.com --role 'roles/logging.viewer'
$ gcloud iam service-accounts keys create $PWD/swb-logs-reader-key.json --iam-account swb-logs-reader@<your gce project id>.iam.gserviceaccount.com
```

1. Create a k8s secret containing the service account keys:

```
kubectl create secret generic stackdriver-webhook-bridge --from-file=key.json=$PWD/swb-logs-reader-key.json
```

1. Deploy the bridge program to your cluster using the provided [stackdriver-webhook-bridge.yaml](https://github.com/sysdiglabs/stackdriver-webhook-bridge/blob/master/stackdriver-webhook-bridge.yaml) file:

```
kubectl apply -f stackdriver-webhook-bridge.yaml -n sysdig-agent
```

The bridge program routes audit events to the domain name `sysdig-agent.sysdig-agent.svc.cluster.local`, which corresponds to the sysdig-agent service you created when you deployed the agent.

## Amazon EKS

These instructions were verified with eks.5 on Kubernetes v1.14.

Amazon EKS does not provide webhooks for audit logs, but it allows audit logs to be forwarded to [CloudWatch](https://aws.amazon.com/cloudwatch/). In order to access CloudWatch logs from the Sysdig Agent we can proceed as follows:

1. Enable CloudWatch logs for our EKS cluster
1. Allow access to CloudWatch from the worker nodes
1. Add a new deployment that polls CloudWatch and forwards events to the Sysdig Agent

You can find an [example configuration](https://github.com/sysdiglabs/ekscloudwatch) that can be implemented with the AWS UI (whereas in a production system it would be implemented as IaC scripts) along with the code and the image for an example audit log forwarder.

Please note that CloudWatch is an additional AWS paid offering. In addition, with this solution all the pods running on the worker nodes will be allowed to read CloudWatch logs through AWS APIs.

## RKE, using K8s >= 1.13

These instructions were verified with RKE v1.0.0 and K8s v1.16.3. It should work with versions as old as 1.13.

K8s Audit support is already enabled by default, but the audit policy must be updated to provide additional granularity. These instructions enable a webhook backend pointing to the agent's service. Dynamic audit backends are not supported as there isn't a way to enable the audit feature flag.

1. On each K8s API Master Node, create the directory `/var/lib/k8s_audit`.
1. On each K8s API Master Node, copy the provided [audit-policy.yaml](./audit-policy.yaml) file to the minikube vm into the directory `/var/lib/k8s_audit`. This directory will be mounted into the api server, giving it access to the audit/webhook files.
1. Follow the instructions described in [Creating a webhook configuration file](#Creating a webhook configuration file)] to create a `webhook-config.yaml` file and copy it to each K8s API Master Node into the directory `/var/lib/k8s_audit`.
1. Modify your RKE cluster configuration `cluster.yml` to add `extra_args` and `extra_binds` sections to the `kube-api` section. Here's an example:

```
kube-api:
...
    extra_args:
      audit-policy-file: /var/lib/k8s_audit/audit-policy.yaml
      audit-webhook-config-file: /var/lib/k8s_audit/webhook-config.yaml
      audit-webhook-batch-max-wait: 5s
    extra_binds:
    - /var/lib/k8s_audit:/var/lib/k8s_audit
...
```

This changes the command line arguments for the api server to use an alternate audit policy and to use the webhook backend you created.

1. Restart the RKE cluster via `rke up`.


## IKS

IKS supports routing K8s audit events to a single configurable webhook backend url. It does not support dynamic audit sinks and does not support the ability to change the audit policy that controls which k8s audit events are sent.

The default audit policy generally does not include events at the Request or RequestResponse levels, meaning that any rules that look in detail at the objects being created/modified (e.g. rules using the `ka.req.*` and `ka.resp.*` fields) will not trigger. This includes the following rules:

* Create Disallowed Pod
* Create Privileged Pod
* Create Sensitive Mount Pod
* Create HostNetwork Pod
* Pod Created in Kube Namespace
* Create NodePort Service
* Create/Modify Configmap With Private Credentials
* Attach to cluster-admin Role
* ClusterRole With Wildcard Created
* ClusterRole With Write Privileges Created
* ClusterRole With Pod Exec Created

These instructions were adapted from the [IBM Provided Instructions](https://cloud.ibm.com/docs/containers?topic=containers-health&locale=en%5C043science#configuring), which assume K8s audit events are sent to fluentd instead of the sysdig agent.

1. Set the webhook backend url to the IP address of the sysdig-agent service:

```
$ ibmcloud ks cluster master audit-webhook set --cluster <cluster_name_or_ID> --remote-server http://$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent):7765/k8s_audit
```

1. Verify that the webhook backend url has been set:
```
ibmcloud ks cluster master audit-webhook get --cluster <cluster_name_or_ID>
```

1. Apply the webhook to your Kubernetes API server by refreshing the cluster master. It might take several minutes for the master to refresh.

```
ibmcloud ks cluster master refresh --cluster <cluster_name_or_ID>
```

## Minikube, using K8s >= 1.11/1.12

These instructions were verified using minikube 1.2.0. Other minikube versions should also work as long as they run K8s versions 1.11/1.12. When using K8s 1.11/1.12, only webhook backends are supported.

In all cases below, "the minikube vm" refers to the VM created by minikube. In cases where you're using --vm-driver=none, this means the local machine.

1. On the minikube vm, create the directory `/var/lib/k8s_audit`.
1. Copy the provided [audit-policy.yaml](./audit-policy.yaml) file to the minikube vm into the directory `/var/lib/k8s_audit`. This directory will be mounted into the api server, giving it access to the audit/webhook files.
1. Follow the instructions described in [Creating a webhook configuration file](#Creating a webhook configuration file)] to create a `webhook-config.yaml` file and copy it to the minikube vm into the directory `/var/lib/k8s_audit`.
1. Modify the K8s api server manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml`, adding the following command line arguments:

* --audit-log-path=/var/lib/k8s_audit/k8s_audit_events.log
* --audit-policy-file=/var/lib/k8s_audit/audit-policy.yaml
* --audit-log-maxbackup=1
* --audit-log-maxsize=10
* --audit-webhook-config-file=/var/lib/k8s_audit/webhook-config.yaml
* --audit-webhook-batch-max-wait=5s

Command line arguments are provided in the container spec as arguments to the program `/usr/local/bin/kube-apiserver`. The relevant section of the manifest will look like this:

```yaml
spec:
  containers:
  - command:
    - kube-apiserver --allow-privileged=true --anonymous-auth=false
      --audit-log-path=/var/lib/k8s_audit/audit.log
      --audit-policy-file=/var/lib/k8s_audit/audit-policy.yaml
      --audit-log-maxbackup=1
      --audit-log-maxsize=10
      --audit-webhook-config-file=/var/lib/k8s_audit/webhook-config.yaml
      --audit-webhook-batch-max-wait=5s
      ...
```

1. Modify the K8s api server manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml` to add a mount of /var/lib/k8s_audit into the kube-apiserver container. The relevant sections look like this:

```yaml
    volumeMounts:
    - mountPath: /var/lib/k8s_audit/
    ...
    volumes:
  - hostPath:
      path: /var/lib/k8s_audit
    ...
```

1. Modifying the manifest will cause the K8s api server to automatically restart. Once restarted, it will route K8s audit events to the agent's service.

## Minikube, using K8s >= 1.13

These instructions were verified using minikube 1.2.0. Other minikube versions should also work as long as they run K8s versions 1.13. When using 1.13, these instructions enable dynamic sinks, but still require changes to the kube-apiserver command line arguments.

In all cases below, "the minikube vm" refers to the VM created by minikube. In cases where you're using --vm-driver=none, this means the local machine.

1. On the minikube vm, create the directory `/var/lib/k8s_audit`.
1. Copy the provided [audit-policy.yaml](./audit-policy.yaml) file to the minikube vm into the directory `/var/lib/k8s_audit`. This directory will be mounted into the api server, giving it access to the audit/webhook files.
1. Modify the K8s api server manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml`, adding the following command line arguments:

* --audit-log-path=/var/lib/k8s_audit/k8s_audit_events.log
* --audit-policy-file=/var/lib/k8s_audit/audit-policy.yaml
* --audit-log-maxbackup=1
* --audit-log-maxsize=10
* --audit-dynamic-configuration
* --feature-gates=DynamicAuditing=true
* --runtime-config=auditregistration.k8s.io/v1alpha1=true

Command line arguments are provided in the container spec as arguments to the program `/usr/local/bin/kube-apiserver`. The relevant section of the manifest will look like this:

```yaml
spec:
  containers:
  - command:
    - kube-apiserver --allow-privileged=true --anonymous-auth=false
      --audit-log-path=/var/lib/k8s_audit/audit.log
      --audit-policy-file=/var/lib/k8s_audit/audit-policy.yaml
      --audit-log-maxbackup=1
      --audit-log-maxsize=10
      --audit-dynamic-configuration
      --feature-gates=DynamicAuditing=true
      --runtime-config=auditregistration.k8s.io/v1alpha1=true
      ...
```

1. Modify the K8s api server manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml` to add a mount of /var/lib/k8s_audit into the kube-apiserver container. The relevant sections look like this:

```yaml
    volumeMounts:
    - mountPath: /var/lib/k8s_audit/
    ...
    volumes:
  - hostPath:
      path: /var/lib/k8s_audit
    ...
```

1. Modifying the manifest will cause the K8s api server to automatically restart.
1. Follow the instructions described in [Create an Audit Sink Pointing to the Agent Service](#Create an Audit Sink Pointing to the Agent Service)] to create and apply a dynamic audit sink. Once the dynamic audit sink is created, it will route K8s audit events to the agent's service.

## Creating a webhook configuration file

[webhook-config.yaml.in](./webhook-config.yaml.in) is a (templated) webhook resource file that sends audit events to an ip associated with the Sysdig Agent service, port 7765. It is templated in that the *actual* ip is defined in an environment variable `AGENT_SERVICE_CLUSTERIP`, which can be plugged in using a program like `envsubst`.

Run the following to fill in the template file with the ClusterIP ip address associated with the `sysdig-agent` service you created when you installed the agent. Although service domain names like `sysdig-agent.sysdig-agent.svc.cluster.local` can not be resolved from the k8s api server (they're typically run as pods but not *really* a part of the cluster), the ClusterIPs associated with those services are routable.

```
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent) envsubst < webhook-config.yaml.in > webhook-config.yaml
```

## Create an Audit Sink Pointing to the Agent Service

When using dynamic audit sinks, you need to create an Audit Sink object that directs audit events to the sysdig agent service. A template file [audit-sink.yaml.in](./audit-sink.yaml.in) in this directory can be used to create the sink. Like the audit policy file above, it must be filled in using the ClusterIP address of the sysdig-agent service, using a command line:

```
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent) envsubst < audit-sink.yaml.in > audit-sink.yaml
```

# How to test that K8s audit logs are working

To test that K8s audit events are being properly passed to the agent, you can do any of the following:

1. Enable the disabled-by-default policy "All K8s Activity". It will result in a policy event for every K8s Audit event, so it should only be enabled temporarily.
1. The policy "All K8s Object Modifications" will result in a policy event any time a deployment/service/configmap/namespace is created.
1. You can use the [falco-event-generator](https://falco.org/docs/event-sources/sample-events/) docker image with the "k8s_audit" argument, via a command line like the following:

```
docker run -v $HOME/.kube:/root/.kube -it falcosecurity/falco-event-generator k8s_audit
```

This will create resources in a namespace `falco-event-generator`.

# Script to automate configuration changes

As a convienence, we've created a script [enable-k8s-audit.sh](./enable-k8s-audit.sh) that performs the necessary steps of enabling audit log support for all K8s distributions described above, other than EKS. You can run it via: `bash enable-k8s-audit.sh <distribution>`, where `<distribution>` is one of the following:

* minishift-3.11
* openshift-3.11
* openshift-4.2
* gke
* iks
* rke-1.13: Implies K8s >= 1.13
* kops
* minikube-1.13: Implies K8s >= 1.13
* minikube-1.12: Implies K8s 1.11/1.12

It should be run from the sysdig-cloud-scripts/k8s_audit_config directory.

In some cases it may prompt for the GCE Project Id, IKS Cluster Name, etc. For minikube/openshift-3.11/minishift-3.11, it will use ssh/scp to copy files to and run scripts on the API Master node. Otherwise, it should be fully automated.
