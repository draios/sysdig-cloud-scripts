<!-- Space: TOOLS -->
<!-- Parent: Installer -->
<!-- Title: Network Policies v2 in the installer -->
<!-- Layout: plain -->

# Network Policies

<br />

<!-- Include: ac:toc -->

<br />

## Introduction

The current version of Sysdig Network Policies v2 supports Sysdig HAProxy Ingress and IBM Cloud IKS ALBs.

The NetworkPolicies (NP) are controlled via two flags:

- (`.networkPolicies.ingress.default`) controls if the manifests will be generated at all or not. Manifests will be generated only if this flag is set to `deny`.

- (`.networkPolicies.enabled`) controls if the NPs are active or not. This flag controls if the entries required under `.spec` to enable the NPs are rendered or not.

In order to generate the manifests and enable the NPs, `networkPolicies.enabled` must be set to `true` and `networkPolicies.ingress.default` must be set to `deny`.

A validation checks that the minimal requirements for each type of environment (via the `.deployment` parameter) are met:

- if `.deployment=kubernetes`, then the `.networkPolicies.ingress.haproxy.allowedNetworks` is required

- if `.deployment=iks`, then the `.networkPolicies.ingress.alb

## Parameters

### **networkPolicies.enabled**

**Required**: `false`<br />
**Description**: to activate or de-activate NetworkPolicies. This flag works together with next flag `networkPolicies.ingress.default`. It controls whether the actual `.spec` section of the NP is enabled or not.<br />
**Options**: `true|false`<br />
**Default**: `false`<br />

**Example**:

```yaml
networkPolicies:
  enabled: true
```

### **networkPolicies.ingress.default**

**Required**: `false` <br />
**Description**: to render the NetworkPolicies this flag must be set to `deny`. It works together with flag `networkPolicies.enabled`.<br />
**Options**: `deny`/`allow`<br />
**Default**: `false`<br />

**Example**:

```yaml
networkPolicies:
  enabled: "true"
  ingress:
    default: "deny"
```

### **networkPolicies.ingress.haproxy.allowedNetworks**

**Required**: `true` (if NPs are enabled and active and `.deployment=kubernetes`)<br />
**Description**: If NPs are enabled (`.networkPolicies.enabled` to `"true"` and `.networkPolicies.ingress.default` to `"deny"`), then this value is required. It's the CIDR (or CIDRs) used by the HAPROXY Ingress controller<br />
**Options**: a list of valid IP Network address/Netmask entries<br />
**Default**: None<br />

**Example**:

```yaml
deployment: kubernetes
networkPolicies:
  enabled: "true"
  ingress:
    default: "deny"
  haproxy:
    allowedNetworks:
      - 100.96.0.0/11
```

### **networkPolicies.ingress.alb.selector**

**Required**: `true` (if `.deployment=iks`)<br />
**Description**: In IKS the list of ALBs must be specified via the `app` label<br />
**Options**: A list of "app" label values to match ALB deployments to permit traffic from; make it `null` to exclude ALBs from generated rules<br />
**Default**: `None`<br />

**Example**:

```yaml
deployment: iks
networkPolicies:
  enabled: "true"
  ingress:
    default: "deny"
    alb:
      # -- (map) A list of "app" label values to match ALB deployments to permit traffic from; make it `null` to exclude ALBs from generated rules
      selector: {}
      # selector:
      #   matchExpressions:
      #   - key: app
      #     operator: In
      #     values: ["public-cr<clusterid>-alb1", "public-cr<clusterid>-alb2"]
```
