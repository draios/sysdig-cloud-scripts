#!/bin/bash
set -euo pipefail

#generate sysdigcloud support bundle on kubernetes

LABELS=""
CONTEXT=""
CONTEXT_OPTS=""
NAMESPACE=""
LOG_DIR=$(mktemp -d sysdigcloud-support-bundle-XXXX)

while getopts l:n:c:hced flag; do
    case "${flag}" in
        l) LABELS=${OPTARG:-};;
        n) NAMESPACE=${OPTARG:-};;
        h) 

            echo "Usage: ./get_support_bundle.sh -n <NAMESPACE> -l <LABELS>"; 
            echo "Example: ./get_support_bundle.sh -n sysdig -l api,collector,worker,cassandra,elasticsearch"; 
            echo "Flags:"; 
            echo "-n  Specify the Sysdig namespace. If not specified, "sysdigcloud" is assumed."; 
            echo "-c  Specify the kubectl context. If not set, the current context will be used."; 
            echo "-l  Specify Sysdig pod role label to collect (e.g. api,collector,worker)";
            echo "-h  Print these instructions";
            exit;;

        c) CONTEXT=${OPTARG:-};;
    esac
done

if [[ -z ${NAMESPACE} ]]; then
    NAMESPACE="sysdig"
fi

if [[ ! -z ${CONTEXT} ]]; then
    CONTEXT_OPTS="--context=${CONTEXT}"
fi

# Set options for kubectl commands
KUBE_OPTS="--namespace ${NAMESPACE} ${CONTEXT_OPTS}"

#verify that the provided namespace exists
KUBE_OUTPUT=$(kubectl ${KUBE_OPTS} get namespace ${NAMESPACE}) || true

# Check that the supplied namespace exists, and if not, output current namespaces
if [[ "$(echo "$KUBE_OUTPUT" | grep -o "^sysdig " || true)" != "${NAMESPACE} " ]]; then
    echo "We could not determine the namespace. Please check the spelling and try again";
    echo "kubectl ${KUBE_OPTS} get ns";
    echo "$(kubectl ${KUBE_OPTS} get ns)";
fi

# Configure kubectl command if labels are set
if [[ -z ${LABELS} ]]; then
    SYSDIGCLOUD_PODS=$(kubectl ${KUBE_OPTS} get pods | awk '{ print $1 }' | grep -v NAME)
else
    SYSDIGCLOUD_PODS=$(kubectl ${KUBE_OPTS} -l "role in (${LABELS})" get pods | awk '{ print $1 }' | grep -v NAME)
fi

echo "Using namespace ${NAMESPACE}";
echo "Using context ${CONTEXT}";

# Collect container logs for each pod
command='tar czf - /logs/ /opt/draios/ /var/log/sysdigcloud/ /var/log/cassandra/ /tmp/redis.log /var/log/redis-server/redis.log /var/log/mysql/error.log /opt/prod.conf 2>/dev/null || true'
for pod in ${SYSDIGCLOUD_PODS}; 
do
    echo "Getting support logs for ${pod}"
    mkdir -p ${LOG_DIR}/${pod}
    kubectl ${KUBE_OPTS} get pod ${pod} -o json > ${LOG_DIR}/${pod}/kubectl-describe.json
    containers=$(kubectl ${KUBE_OPTS} get pod ${pod} -o json | jq -r '.spec.containers[].name')
    for container in ${containers}; 
    do
        kubectl ${KUBE_OPTS} logs ${pod} -c ${container} > ${LOG_DIR}/${pod}/${container}-kubectl-logs.txt
        kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- bash -c "${command}" > ${LOG_DIR}/${pod}/${container}-support-files.tgz || true
    done;
done;

# Get info on deployments, statefulsets, persistentVolumeClaims, daemonsets, and ingresses
for object in svc deployment sts pvc daemonset ingress replicaset; 
do
    items=$(kubectl ${KUBE_OPTS} get ${object} -o jsonpath="{.items[*]['metadata.name']}")
    mkdir -p ${LOG_DIR}/${object}
    for item in ${items}; 
    do
        kubectl ${KUBE_OPTS} get ${object} ${item} -o json > ${LOG_DIR}/${object}/${item}-kubectl.json
    done;
done;

# Fetch container density information
num_nodes=0
num_pods=0
num_running_containers=0
num_total_containers=0

printf "%-30s %-10s %-10s %-10s %-10s\n" "Node" "Pods" "Running Containers" "Total Containers" >> ${LOG_DIR}/container_density.txt
for node in $(kubectl ${KUBE_OPTS} get nodes --no-headers -o custom-columns=node:.metadata.name);
do
    total_pods=$(kubectl get pods -A --no-headers -o wide | grep ${node} |wc -l |xargs)
    running_containers=$( kubectl get pods -A --no-headers -o wide |grep ${node} |awk '{print $3}' |cut -f 1 -d/ | awk '{ SUM += $1} END { print SUM }' |xargs)
    total_containers=$( kubectl get pods -A --no-headers -o wide |grep ${node} |awk '{print $3}' |cut -f 2 -d/ | awk '{ SUM += $1} END { print SUM }' |xargs)
    printf "%-30s %-15s %-20s %-10s\n" "${node}" "${total_pods}" "${running_containers}" "${total_containers}" >> ${LOG_DIR}/container_density.txt
    num_nodes=$((num_nodes+1))
    num_pods=$((num_pods+${total_pods}))
    num_running_containers=$((num_running_containers+${running_containers}))
    num_total_containers=$((num_total_containers+${total_containers}))
done;
  
printf "\nTotals\n-----\n" >> ${LOG_DIR}/container_density.txt
printf "Nodes: ${num_nodes}\n" >> ${LOG_DIR}/container_density.txt
printf "Pods: ${num_pods}\n" >> ${LOG_DIR}/container_density.txt
printf "Running Containers: ${num_running_containers}\n" >> ${LOG_DIR}/container_density.txt
printf "Containers: ${num_total_containers}\n" >> ${LOG_DIR}/container_density.txt

# Fetch Cassandra Nodetool output
echo "Fetching Cassandra statistics";
mkdir -p ${LOG_DIR}/cassandra
for pod in $(kubectl ${KUBE_OPTS} get pod -l role=cassandra | grep -v "NAME" | awk '{print $1}')
do
    printf "$pod\t" |tee -a ${LOG_DIR}/cassandra/nodetool_info.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool info >> ${LOG_DIR}/cassandra/nodetool_info.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool status | tee -a ${LOG_DIR}/cassandra/nodetool_status.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool getcompactionthroughput | tee -a ${LOG_DIR}/cassandra/nodetool_getcompactionthroughput.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool cfstats | tee -a ${LOG_DIR}/cassandra/nodetool_cfstats.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool cfhistograms draios message_data10 | tee -a ${LOG_DIR}/cassandra/nodetool_cfhistograms.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool proxyhistograms | tee -a ${LOG_DIR}/cassandra/nodetool_proxyhistograms.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool tpstats | tee -a ${LOG_DIR}/cassandra/nodetool_tpstats.log
    kubectl ${KUBE_OPTS} exec -it $pod -- nodetool compactionstats | tee -a ${LOG_DIR}/cassandra/nodetool_compactionstats.log
done;

# Fetch Elasticsearch storage info
mkdir -p ${LOG_DIR}/elasticsearch
printf "Pod#\tFilesystem\tSize\tUsed\tAvail\tUse\tMounted on\n" |tee -a ${LOG_DIR}/elasticsearch/elasticsearch_storage.log
for pod in $(kubectl ${KUBE_OPTS} get pods -l role=elasticsearch | grep -v "NAME" | awk '{print $1}')
do
    printf "$pod\t" |tee -a elasticsearch_storage.log
    kubectl ${KUBE_OPTS} exec -it $pod -- df -Ph | grep elasticsearch | grep -v "tmpfs" | awk '{printf "%-13s %10s %6s %8s %6s %s\n",$1,$2,$3,$4,$5,$6}' |tee -a ${LOG_DIR}/elasticsearch/elasticsearch_storage.log
done;

# Fetch Cassandra storage info
# Executes a df -h in Cassandra pod, gets proxyhistograms, tpstats, and compactionstats
printf "Pod#\tFilesystem\tSize\tUsed\tAvail\tUse\tMounted on\n" > ${LOG_DIR}/cassandra/cassandra_storage.log
for pod in $(kubectl ${KUBE_OPTS} get pods -l role=cassandra  | grep -v "NAME" | awk '{print $1}')
do
    printf "$pod\t" > ${LOG_DIR}/cassandra/cassandra_storage.log
    kubectl ${KUBE_OPTS} exec -it $pod -- df -Ph | grep cassandra | grep -v "tmpfs" | awk '{printf "%-13s %10s %6s %8s %6s %s\n",$1,$2,$3,$4,$5,$6}' > ${LOG_DIR}/cassandra/cassandra_storage.log
done;

# Collect the sysdigcloud-config configmap, and write to the log directory
kubectl ${KUBE_OPTS} get configmap sysdigcloud-config -o yaml | grep -v password > ${LOG_DIR}/config.yaml

# Generate the bundle name, create a tarball, and remove the temp log directory
BUNDLE_NAME=$(date +%s)_sysdig_cloud_support_bundle.tgz
tar czf ${BUNDLE_NAME} ${LOG_DIR}
rm -rf ${LOG_DIR}

echo "Support bundle generated:" ${BUNDLE_NAME}
