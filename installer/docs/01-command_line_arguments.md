<!-- Space: TOOLS -->
<!-- Parent: Installer -->
<!-- Title: Command Line Arguments -->
<!-- Layout: plain -->

# Command line arguments explained

<br />

## Phase: `deploy`

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

## Phase `import`

`--zookeeper-workloadname <string value>`

- This is the value that will be used for the `zookeeper` StatefulSet.
The default value is `zookeeper`, this argument must be used when the 
actual name of the STS in the cluster differs

`--kafka-workloadname <value>`

- Same as above for `kafka`

`--cassandra-workloadname <value>`

- Same as above for `cassandra`
