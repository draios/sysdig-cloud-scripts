#!/bin/bash

set -euo pipefail

#generate sysdigcloud support bundle on kubernetes
NAMESPACE=${1:-sysdigcloud}
CONTEXT=${2:-}

if [[ -z ${CONTEXT} ]] ; then
    context=""
else
    context="--context ${CONTEXT}"
fi

#verify that the provided namespace exists
kubectl ${context} get namespace ${NAMESPACE} > /dev/null

KUBE_OPTS="--namespace ${NAMESPACE} ${context}"

LOG_DIR=$(mktemp -d sysdigcloud-support-bundle-XXXX)

SYSDIGCLOUD_PODS=$(kubectl ${KUBE_OPTS} get pods | awk '{ print $1 }' | grep -v NAME)

command='tar czf - /logs/ /opt/draios/ /var/log/sysdigcloud/ /var/log/cassandra/ /tmp/redis.log /var/log/redis-server/redis.log /var/log/mysql/error.log /opt/prod.conf 2>/dev/null || true'
for pod in ${SYSDIGCLOUD_PODS}; do
    echo "Getting support logs for ${pod}"
    mkdir -p ${LOG_DIR}/${pod}
    kubectl ${KUBE_OPTS} get pod ${pod} -o json > ${LOG_DIR}/${pod}/kubectl-describe.json
    containers=$(kubectl ${KUBE_OPTS} get pod ${pod} -o json | jq -r '.spec.containers[].name')
    for container in ${containers}; do
        kubectl ${KUBE_OPTS} logs ${pod} -c ${container} > ${LOG_DIR}/${pod}/${container}-kubectl-logs.txt
        kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- bash -c "${command}" > ${LOG_DIR}/${pod}/${container}-support-files.tgz || true
    done
done

for object in svc deployment sts pvc daemonset ingress replicaset; do
    items=$(kubectl ${KUBE_OPTS} get ${object} -o jsonpath="{.items[*]['metadata.name']}")
    mkdir -p ${LOG_DIR}/${object}
    for item in ${items}; do
        kubectl ${KUBE_OPTS} get ${object} ${item} -o json > ${LOG_DIR}/${object}/${item}-kubectl.json
    done
done

kubectl ${KUBE_OPTS} get configmap sysdigcloud-config -o yaml | grep -v password > ${LOG_DIR}/config.yaml

BUNDLE_NAME=$(date +%s)_sysdig_cloud_support_bundle.tgz
tar czf ${BUNDLE_NAME} ${LOG_DIR}
rm -rf ${LOG_DIR}

echo "Support bundle generated:" ${BUNDLE_NAME}
