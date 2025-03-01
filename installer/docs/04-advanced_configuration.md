<!-- Space: IONP -->
<!-- Parent: Installer -->
<!-- Parent: Git Synced Docs -->
<!-- Title: Advanced Configuration -->
<!-- Layout: plain -->

# Advanced Configuration

<br />

<!-- Include: ac:toc -->

<br />

## Use hostPath for Static Storage of Sysdig Components

As described in the Installation Storage Requirements, the Installer assumes usage of a dynamic storage provider (AWS or GKE). If these are not used in your environment, add the entries below to the values.yaml to configure static storage.

Based on the `size` found in the `values.yaml` file (small/medium/large), the Installer assumes a minimum number of replicas and nodes to be provided. You will enter the names of the nodes on which you will run the Cassandra, ElasticSearch and Postgres components of Sysdig in the values.yaml, as in the parameters and example below.

### Parameters

- `storageClassProvisioner`: hostPath.
- `sysdig.cassandra.hostPathNodes`: The number of nodes configured here needs to be at minimum 1 when configured `size` is `small`, 3 when configured `size` is `medium` and 6 when configured `size` is large.
- `elasticsearch.hostPathNodes`: The number of nodes configured here needs to be be at minimum 1 when configured `size` is `small`, 3 when configured `size` is `medium` and 6 when configured `size` is large.
- `sysdig.mysql.hostPathNodes`: When sysdig.mysqlHa is configured to true this has to be at least 3 nodes and when sysdig.mysqlHa is not configured it should be at least one node.
- `sysdig.postgresql.hostPathNodes`: This can be ignored if Sysdig Secure is not licensed or used on this environment. If Secure is used, then the parameter should be set to 1, regardless of the environment size setting.
- `.hostPathCustomPaths`: customize the location of the directory structure on the Kubernetes node
- `.pvStorageSize.<small|medium|large>.<datastoreservice>`: customize the size of Volumes (check in the [configuration parameters list](/docs/02-configuration_parameters.md))

### Example

```yaml
storageClassProvisioner: hostPath
elasticsearch:
  hostPathNodes:
    - my-cool-host1.com
    - my-cool-host2.com
    - my-cool-host3.com
    - my-cool-host4.com
    - my-cool-host5.com
    - my-cool-host6.com
sysdig:
  cassandra:
    hostPathNodes:
      - my-cool-host1.com
      - my-cool-host2.com
      - my-cool-host3.com
      - my-cool-host4.com
      - my-cool-host5.com
      - my-cool-host6.com
  postgresql:
    hostPathNodes:
      - my-cool-host1.com
  kafka:
    hostPathNodes:
      - i-0082bddac2e013639
      - i-05eb2d9719cc2dafa
      - i-082b0341a1bb2f2be
  zookeeper:
    hostPathNodes:
      - i-0082bddac2e013639
      - i-05eb2d9719cc2dafa
      - i-082b0341a1bb2f2be
pvStorageSize:
  medium:
    cassandra: 600Gi
    elasticsearch: 275Gi
    postgresql: 120Gi
hostPathCustomPaths:
  cassandra: /sysdig/cassandra
  elasticsearch: /sysdig/elasticsearch
  mysql: /sysdig/mysql
  postgresql: /sysdig/postgresql    
```

## Installer on EKS

### Creating a cluster

Please do not use eksctl 0.10.0 and 0.10.1 as those are known to be buggy see: kubernetes/kubernetes#73906 (comment)

```bash
eksctl create cluster \
   --name=eks-installer1 \
   --node-type=m5.4xlarge \
   --nodes=3 \
   --version 1.14 \
   --region=us-east-1 \
   --vpc-public-subnets=<subnet1,subnet2>
```

### Additional installer configurations

EKS uses aws-iam-authenticator to authorize kubectl commands.
aws-iam-authenticator needs aws credentials mounted from **~/.aws** to the installer.

```bash
docker run  \
  -v ~/.aws:/.aws \
  -e HOST_USER=$(id -u) \
  -e KUBECONFIG=/.kube/config \
  -v ~/.kube:/.kube:Z \
  -v $(pwd):/manifests:Z \
  quay.io/sysdig/installer:<InstallerVersion>
```

### Running airgapped EKS

```bash
EKS=true bash sysdig_installer.tar.gz
```

The above ensures the `~/.aws` directory is correctly mounted for the airgap installer container.

### Exposing the Sysdig endpoint

Get the external ip/endpoint for the ingress service.

```bash
kubectl -n <namespace>  get service haproxy-ingress-service
```

In route53 create an A record with the dns name pointing to external ip/endpoint.

### Gotchas

Make sure that subnets have internet gateway configured and has enough ips.

## airgapped Installations

### Updating the Feeds Database in airgapped environments [ScanningV2]

In non-airgap onprem environments, the vulnerabilities feeds is automatically retrieved by the Sysdig stack from a Sysdig SaaS endpoint.
In an airgap onprem environment, the customer must retrieve the feed as a Docker image from a workstation with Internet access and then load the image onto their own private registry.

The following is an example of a Bash script that could be used to update the vulnerability feeds used by the ScanningV2 engine.
The tag used is `latest`, and Sysdig is building and pushing this tag multiple times each day.
The details of the image can be found using the `docker inspect` command, even if the tag is `latest`.
The script is only provided as an example or template to be filled and customized.

```bash
#!/bin/bash
QUAY_USERNAME="<change_me>"
QUAY_PASSWORD="<change_me>"
IMAGE_TAG="latest"

# Download image
docker login quay.io/sysdig -u ${QUAY_USERNAME} -p ${QUAY_PASSWORD}
docker image pull quay.io/sysdig/airgap-vuln-feeds:${IMAGE_TAG}
# Save image
docker image save quay.io/sysdig/airgap-vuln-feeds:${IMAGE_TAG} -o airgap-vuln-feeds-latest.tar
# Optionally move image
mv airgap-vuln-feeds-latest.tar /var/shared-folder
# Load image remotely
ssh -t user@airgapped-host "docker image load -i /var/shared-folder/airgap-vuln-feeds-latest.tar"
# Push image remotely
ssh -t user@airgapped-host "docker tag airgap-vuln-feeds:${IMAGE_TAG} airgapped-registry/airgap-vuln-feeds:${IMAGE_TAG}"
ssh -t user@airgapped-host "docker image push airgapped-registry/airgap-vuln-feeds:${IMAGE_TAG}"
# verify the image timestamp - this command should return the timestamp in epoch format
epoch_timestamp=$(ssh -q -t user@airgapped-host "docker inspect --format '{{ index .Config.Labels \"sysdig.origin-docker-image-tag\" }}' airgapped-registry/airgap-vuln-feeds:${IMAGE_TAG}")
human_readable_timestamp=$(date -d@"$epoch_timestamp")
echo "Actual timestamp of the image based on the label sysdig.origin-docker-image-tag: epoch: ${epoch_timestamp} human readable: ${human_readable_timestamp}"


# Update the image: we need to restart the Deployment so that the image will be reloaded
ssh -t user@airgapped-host "kubectl -n <namespace> rollout restart deploy/sysdigcloud-scanningv2-airgap-vuln-feeds"

# Follow and check the restart
ssh -t user@airgapped-host "kubectl -n <namespace> rollout status deploy/sysdigcloud-scanningv2-airgap-vuln-feeds"
```

> Note: The `IMAGE_TAG` mentioned above could also be used with the timestamp as well, like it was used in previous releases, here an example how to re-write the `IMAGE_TAG` line for the timestamp:
> ```
> # Calculate the tag of the last version.
> epoch=`date +%s`
> IMAGE_TAG=$(( $epoch - 86400 - $epoch % 86400))
> ```

The above script could be scheduled using a Linux cronjob that runs every day. E.g.:

```bash
0 8 * * * airgap-vuln-feeds-image-update.sh > /somedir/sysdig-airgapvulnfeed.log 2>&1
```

### Updating the Feeds Database in airgapped Environments [Legacy Scanning]

This is a procedure that can be used to automatically update the feeds database:

1. download the image file quay.io/sysdig/vuln-feed-database-12:latest from Sysdig registry to the jumpbox server and save it locally
2. (Optional) Move the file from the jumpbox server to your airgapped environment.
3. Load the image file and push it to your airgapped image registry.
4. restart the pod sysdigcloud-feeds-db
5. restart the pod feeds-api

Finally, steps 1 to 5 will be performed periodically once a day.

This is an example script that contains all the steps:

```bash
#!/bin/bash
QUAY_USERNAME="<change_me>"
QUAY_PASSWORD="<change_me>"

# Download image
docker login quay.io/sysdig -u ${QUAY_USERNAME} -p ${QUAY_PASSWORD}
docker image pull quay.io/sysdig/vuln-feed-database-12:latest
# Save image
docker image save quay.io/sysdig/vuln-feed-database-12:latest -o vuln-feed-database-12.tar
# Optionally move image
mv vuln-feed-database-12.tar /var/shared-folder
# Load image remotely
ssh -t user@airgapped-host "docker image load -i /var/shared-folder/vuln-feed-database-12.tar"
# Push image remotely
ssh -t user@airgapped-host "docker tag vuln-feed-database-12:latest airgapped-registry/vuln-feed-database-12:latest"
ssh -t user@airgapped-host "docker image push airgapped-registry/vuln-feed-database-12:latest"
# Restart database pod
ssh -t user@airgapped-host "kubectl -n sysdigcloud scale deploy sysdigcloud-feeds-db --replicas=0"
ssh -t user@airgapped-host "kubectl -n sysdigcloud scale deploy sysdigcloud-feeds-db --replicas=1"
# Restart feeds-api pod
ssh -t user@airgapped-host "kubectl -n sysdigcloud scale deploy sysdigcloud-feeds-api --replicas=0"
ssh -t user@airgapped-host "kubectl -n sysdigcloud scale deploy sysdigcloud-feeds-api --replicas=1"
```

The script can be scheduled using a cron job that run every day

```bash
0 8 * * * feeds-database-update.sh >/dev/null 2>&1
```
