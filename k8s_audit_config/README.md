# Introduction

This page describes how to get K8s Audit Logging working with the Sysdig Agent. For now, we'll describe how to enable audit logging in k8s 1.11, where the audit configuration needs to be directly provided to the api server. In 1.13 there is a different mechanism that allows audit confguration to be managed like other k8s objects, but these instructions are for 1.11.

These instructions assume that the K8s cluster has *no* audit configuration or logging in place, and are adding configuration to route audit log messages only to the sysdig agent.

The main steps are:

1. Determine if your K8s variant supports audit logging
1. Deploy the Sysdig Agent to your K8s cluster
1. Define your audit policy and webhook configuration
1. Restart the API Server to enable Audit Logging
1. Observe K8s audit events at the Sysdig Agent

## Determine if your K8s variant supports audit logging

K8s Audit Logging is a relatively new feature, and in k8s 1.11 requires modifying the apiserver configuration. As a result, not every K8s Variant exposes the necessary configuration options to enable and configure audit logging. These instructions have been verified to work with the following K8s Variants:

* Minikube (>= 0.33.1) with the default virtualbox driver.
* Kops (>= 1.11.0) using AWS.

## Deploy Sysdig Agent to your K8s cluster

Follow the [Agent Installation Instructions for Kubernetes](https://sysdigdocs.atlassian.net/wiki/x/uQB3Cw) to create a Sysdig Agent service account, service, configmap, and daemonset.

## Define your audit policy and webhook configuration

The files in this directory can be used to configure k8s audit logging. The relevant files are:

* [audit-policy.yaml](./audit-policy.yaml): The k8s audit log configuration we recommend that is compatible with the default k8s audit rules published by Sysdig.
* [webhook-config.yaml.in](./webhook-config.yaml.in): A (templated) webhook configuration that sends audit events to an ip associated with the Sysdig Agent service, port 7765. It is templated in that the *actual* ip is defined in an environment variable `AGENT_SERVICE_CLUSTERIP`, which can be plugged in using a program like `envsubst`.

Run the following to fill in the template file with the ClusterIP ip address you created with the `sysdig-agent` service above. Although services like `sysdig-agent.default.svc.cluster.local` can not be resolved from the kube-apiserver container within the minikube vm (they're run as pods but not *really* a part of the cluster), the ClusterIPs associated with those services are routable.

```
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent) envsubst < webhook-config.yaml.in > webhook-config.yaml
```

## Restart the API Server to enable Audit Logging

A script [enable-k8s-audit.sh](./enable-k8s-audit.sh) performs the necessary steps of enabling audit log support for the apiserver, including copying the audit policy/webhook files to the apiserver machine, modifying the apiserver command line to add `--audit-log-path`, `--audit-policy-file`, etc. arguments, etc. This will result in the API Server restarting, as any change to kube-apiserver.yaml triggers a restart.

For minikube, ideally you'd be able to pass options like `--audit-log-path`, etc. directly on the `minikube start` command line, but manual patching is necessary. See [this issue](https://github.com/kubernetes/minikube/issues/2741) for more details.

It is run as `bash ./enable-k8s-audit.sh <variant>`. `<variant>` can be one of the following:

* "minikube"
* "kops"

When running with variant="kops", the api server hostname will be derived from the current kubectl context name, adding an "api." prefix. If you want to use a different api server hostname, you must either modify the script to specify the kops apiserver hostname or set it via the environment: `APISERVER_HOST=api.my-kops-cluster.com bash ./enable-k8s-audit.sh kops`

Its output looks like this:

```
$ bash enable-k8s-audit.sh minikube
***Copying audit policy/webhook files to apiserver...
audit-policy.yaml                                                                           100% 2519     1.2MB/s   00:00
webhook-config.yaml                                                                         100%  248   362.0KB/s   00:00
apiserver-config.patch.sh                                                                   100% 1190     1.2MB/s   00:00
***Modifying k8s apiserver config (will result in apiserver restarting)...
***Done!
$
```

## (Dynamic only) Create an Audit Sink Pointing to the Agent Service

When using dynamic audit sinks, you need to create an Audit Sink object that directs audit events to the sysdig agent service. A template file [audit-sink.yaml.in](./audit-sink.yaml.in) in this directory can be used to create the sink. Like the audit policy file above, it must be filled in using the ClusterIP address of the sysdig-agent service, using a command line:

```
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent) envsubst < audit-sink.yaml.in > audit-sink.yaml
```

Then you can create it via: `kubectl apply -f audit-sink.yaml -n sysdig-agent`.

## Observe K8s audit events at Sysdig Agent

K8s audit events will then be routed to the Sysdig Agent daemonset within the cluster, which you can observe via the Sysdig Secure Policy Events tab.
