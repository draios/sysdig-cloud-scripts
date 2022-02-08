#!/bin/bash
set -euo pipefail

#generate sysdigcloud agent bundle on kubernetes

LABELS=""
CONTEXT=""
CONTEXT_OPTS=""
NAMESPACE=""
LOG_DIR=$(mktemp -d sysdigcloud-agent-bundle-XXXX)
SINCE_OPTS=""
SINCE=""
API_KEY=""

while getopts l:n:c:s:a:hced flag; do
    case "${flag}" in
        n) NAMESPACE=${OPTARG:-};;
        h)

            echo "Usage: ./get_agent_bundle.sh -n <NAMESPACE>";
            echo "Example: ./get_support_bundle.sh -n sysdig -l api,collector,worker,cassandra,elasticsearch";
            echo "Flags:";
            echo "-n  Specify the Sysdig namespace. If not specified, "sysdig-agent" is assumed.";
            echo "-c  Specify the kubectl context. If not set, the current context will be used.";
            echo "-h  Print these instructions";
            echo "-s  Specify the timeframe of logs to collect (e.g. -s 1h)"
            exit;;

        c) CONTEXT=${OPTARG:-};;
        s) SINCE=${OPTARG:-};;

    esac
done

if [[ -z ${NAMESPACE} ]]; then
    NAMESPACE="sysdig-agent"
fi

if [[ ! -z ${CONTEXT} ]]; then
    CONTEXT_OPTS="--context=${CONTEXT}"
fi

if [[ ! -z ${SINCE} ]]; then
    SINCE_OPTS="--since ${SINCE}"
fi

# Set options for kubectl commands
KUBE_OPTS="--namespace ${NAMESPACE} ${CONTEXT_OPTS}"

#verify that the provided namespace exists
KUBE_OUTPUT=$(kubectl ${KUBE_OPTS} get namespace ${NAMESPACE}) || true

# Check that the supplied namespace exists, and if not, output current namespaces
#if [[ "$(echo "$KUBE_OUTPUT" | grep -o "^sysdig-agent" || true)" != "${NAMESPACE} " ]]; then
#    echo "We could not determine the namespace. Please check the spelling and try again";
#    echo "kubectl ${KUBE_OPTS} get ns";
#    echo "$(kubectl ${KUBE_OPTS} get ns)";
#fi

# Determine the # of agents
NUM_AGENT_PODS=$(kubectl ${KUBE_OPTS} -n sysdig-agent get po | sed -n '2!p' | wc -l)
if
    [ $NUM_AGENT_PODS == "4" ]; then
    echo "the number of pods is 4";
fi


# Limit collection pool to a subset of agents
# Determine which agent is delegated and collect logs from that agent
mkdir -p ${LOG_DIR}/delegated
DELEGATED_NODES=$(kubectl ${KUBE_OPTS} logs sysdig-agent-zmqhv | grep -i delegated | grep -v "K8S delegated nodes:" | awk '{print $9}' | sort --unique)
DELEGATED_PODS=$(for i in ${DELEGATED_NODES}; do kubectl -n sysdig-agent get pod -o wide | grep -i $i | awk '{print $1}' ; done)
for pod in ${DELEGATED_PODS}; do
    mkdir -p ${LOG_DIR}/delegated/$pod
    kubectl ${KUBE_OPTS} cp $pod:/opt/draios/logs/ ${LOG_DIR}/delegated/$pod
    echo "delegated agent logs collected for pod $pod"
done

# Collect the agent configmap and daemonset
echo "Collecting the agent configmap and daemonset"
mkdir -p ${LOG_DIR}/manifest
AGENT_CM=$(kubectl ${KUBE_OPTS} get cm | sed -n '1!p' | awk '{print $1}')
AGENT_DS=$(kubectl ${KUBE_OPTS} get ds | sed -n '1!p' | awk '{print $1}')
kubectl ${KUBE_OPTS} get cm ${AGENT_CM} -o yaml | grep -v apiVersion >> ${LOG_DIR}/manifest/agent_configmap.txt
kubectl ${KUBE_OPTS} get ds ${AGENT_DS} -o yaml | grep -v apiVersion >> ${LOG_DIR}/manifest/agent_daemonset.txt

# Perform connectivity tests and log the result
echo "Performing connectivity tests"
mkdir -p ${LOG_DIR}/connectivity_tests
COLLECTOR=$(kubectl ${KUBE_OPTS} get cm ${AGENT_CM} -o yaml | grep -v apiVersion | grep -i collector: | awk '{print $2}')
COLLECTOR_PORT=$(kubectl ${KUBE_OPTS} get cm sysdig-agent -o yaml | grep -v apiVersion | grep -i "collector_port" | awk '{print $2}')
for pod in ${DELEGATED_PODS}; do
    mkdir -p ${LOG_DIR}/connectivity_tests/$pod
    echo | kubectl ${KUBE_OPTS} exec -it $pod -- openssl s_client -connect ${COLLECTOR}:${COLLECTOR_PORT} >> ${LOG_DIR}/connectivity_tests/$pod/openssl.txt
done

# Generate the bundle name, create a tarball, and remove the temp log directory
BUNDLE_NAME=$(date +%s)_sysdig_agent_support_bundle.tgz
tar czf ${BUNDLE_NAME} ${LOG_DIR}
rm -rf ${LOG_DIR}

echo "Support bundle generated:" ${BUNDLE_NAME}
