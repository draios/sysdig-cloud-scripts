#!/bin/bash
set -euo pipefail

trap 'catch' ERR
catch() {
  echo "An error has occurred. Please check your input and try again. Run this script with the -d flag for debugging"
}

#generate sysdigcloud support bundle on kubernetes

LABELS=""
CONTEXT=""
CONTEXT_OPTS=""
NAMESPACE="sysdig"
LOG_DIR=$(mktemp -d sysdigcloud-support-bundle-XXXX)
SINCE_OPTS=""
SINCE=""
API_KEY=""
SKIP_LOGS="false"
ELASTIC_CURL=""

print_help() {
    printf 'Usage: %s [-a|--api-key <API_KEY>] [c|--context <CONTEXT>] [-d|--debug] [-l|--labels <LABELS>] [-n|--namespace <NAMESPACE>] [-s|--since <TIMEFRAME>] [--skip-logs] [-h|--help]\n' "$0"
    printf "\t%s\n" "-a,--api-key: Provide the Superuser API key for advanced data collection"
    printf "\t%s\n" "-c,--context: Specify the kubectl context. If not set, the current context will be used."
    printf "\t%s\n" "-d,--debug: Enables Debug"
    printf "\t%s\n" "-l,--labels: Specify Sysdig pod role label to collect (e.g. api,collector,worker)"
    printf "\t%s\n" "-n,--namespace: Specify the Sysdig namespace. (default: ${NAMESPACE})"
    printf "\t%s\n" "-s,--since: Specify the timeframe of logs to collect (e.g. -s 1h)"
    printf "\t%s\n" "--skip-logs: Skip all log collection. (default: ${SKIP_LOGS})"
    printf "\t%s\n" "-h,--help: Prints help"
}

parse_commandline() {
    while test $# -gt 0
    do
        _key="$1"
        case "$_key" in
            -a|--api-key)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                API_KEY="$2"
                shift
                ;;
            -c|--context)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                CONTEXT="$2"
                shift
                ;;
            -d|--debug)
                set -x
                ;;
            -d*)
                set -x
                ;;
            -l|--labels)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                LABELS="$2"
                shift
                ;;
            -n|--namespace)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                NAMESPACE="$2"
                shift
                ;;
            -s|--since)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                SINCE="$2"
                shift
                ;;
            --skip-logs)
                SKIP_LOGS="true"
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            -h*)
                print_help
                exit 0
                ;;
        esac
        shift
    done
}

get_agent_version_metric_limits() {
# function used to get metric JSON data for Agent versions and metric counts for each agent.
# This is taken from the Sysdig Agent and Health Status Dashboard
# arguments:
        PARAMS=(
          -sk --location --request POST "${API_URL}/api/data/batch?metricCompatibilityValidation=true&emptyValuesAsNull=true"
          --header 'X-Sysdig-Product: SDC'
          --header "Authorization: Bearer ${API_KEY}"
          --header 'Content-Type: application/json'
          -d "{\"requests\":[{\"format\":{\"type\":\"data\"},\"time\":{\"from\":${FROM_EPOCH_TIME}000000,\"to\":${TO_EPOCH_TIME}000000,\"sampling\":600000000},\"metrics\":{\"v0\":\"agent.version\",\"v1\":\"agent.mode\",\"v2\":\"metricCount.statsd\",\"v3\":\"metricCount.prometheus\",\"v4\":\"metricCount.appCheck\",\"v5\":\"metricCount.jmx\",\"k1\":\"host.hostName\",\"k2\":\"host.mac\"},\"group\":{\"aggregations\":{\"v0\":\"concat\",\"v1\":\"concat\",\"v2\":\"max\",\"v3\":\"max\",\"v4\":\"avg\",\"v5\":\"avg\"},\"groupAggregations\":{\"v0\":\"concat\",\"v1\":\"concat\",\"v2\":\"sum\",\"v3\":\"sum\",\"v4\":\"avg\",\"v5\":\"avg\"},\"by\":[{\"metric\":\"k1\"},{\"metric\":\"k2\"}],\"configuration\":{\"groups\":[{\"groupBy\":[]}]}},\"paging\":{\"from\":0,\"to\":9999},\"sort\":[{\"v0\":\"desc\"},{\"v1\":\"desc\"},{\"v2\":\"desc\"},{\"v3\":\"desc\"},{\"v4\":\"desc\"},{\"v5\":\"desc\"}],\"scope\":null,\"compareTo\":null}]}"
        )
        curl "${PARAMS[@]}" >${LOG_DIR}/metrics/agent_version_metric_limits.json || echo "Curl failed collecting agent_version_metric_limits.json data!" && true
}

get_metrics() {
# function used to get metric JSON data for particular metrics we are interested in from the agent
# arguments:
# 1 - metric_name
# 2 - segment_by
metric="${1}"
segment_by="${2}"

        PARAMS=(
          -sk --location --request POST "${API_URL}/api/data/batch?metricCompatibilityValidation=true&emptyValuesAsNull=true"
          --header 'X-Sysdig-Product: SDC'
          --header "Authorization: Bearer ${API_KEY}"
          --header 'Content-Type: application/json'
          -d "{\"requests\":[{\"format\":{\"type\":\"data\"},\"time\":{\"from\":${FROM_EPOCH_TIME}000000,\"to\":${TO_EPOCH_TIME}000000,\"sampling\":600000000},\"metrics\":{\"v0\":\"${metric}\",\"k0\":\"timestamp\",\"k1\":\"${segment_by}\"},\"group\":{\"aggregations\":{\"v0\":\"avg\"},\"groupAggregations\":{\"v0\":\"avg\"},\"by\":[{\"metric\":\"k0\",\"value\":600000000},{\"metric\":\"k1\"}],\"configuration\":{\"groups\":[{\"groupBy\":[]}]}},\"paging\":{\"from\":0,\"to\":9999},\"sort\":[{\"v0\":\"desc\"}],\"scope\":null,\"compareTo\":null}]}'"
        )
        curl "${PARAMS[@]}" >${LOG_DIR}/metrics/${metric}_${segment_by}.json || echo "Curl failed collecting ${metric}_${segment_by} data!" && true
}

main() {
    local error
    local RETVAL

    if [[ ! -z ${CONTEXT} ]]; then
        CONTEXT_OPTS="--context=${CONTEXT}"
    fi

    if [[ ! -z ${SINCE} ]]; then
        SINCE_OPTS="--since ${SINCE}"
    fi

    # Set options for kubectl commands
    KUBE_OPTS="--namespace ${NAMESPACE} ${CONTEXT_OPTS}"

    #verify that the provided namespace exists
    KUBE_OUTPUT=$(kubectl ${CONTEXT_OPTS} get namespace ${NAMESPACE} --no-headers >/dev/null 2>&1) && RETVAL=$? && error=0 || { RETVAL=$? && error=1; }

    if [[ ${error} -eq 1 ]]; then
        echo "We could not determine the namespace. Please check the spelling and try again.  Return Code: ${RETVAL}"
        echo "kubectl ${CONTEXT_OPTS} get ns | grep ${NAMESPACE}"
        exit 1
    fi

    # If API key is supplied, collect streamSnap, Index settings, and fastPath settings
    if [[ ! -z ${API_KEY} ]]; then
        #Check if we are on version 6
        VERSION_CHECK=$(kubectl ${KUBE_OPTS} get cm | grep 'sysdigcloud-api-config' | wc -l | sed 's/       //g') || true
        echo "version check is ${VERSION_CHECK}"
        if [[ ${VERSION_CHECK} == 1 ]]; then
            VERSION=6
            API_URL=$(kubectl ${KUBE_OPTS} get cm sysdigcloud-collector-config -ojsonpath='{.data.collector-config\.conf}' | awk 'p&&$0~/"/{gsub("\"","");print} /{/{p=0} /sso/{p=1}' | grep serverName | awk '{print $3}')
        else
            VERSION=5
            API_URL=$(kubectl ${KUBE_OPTS} get cm sysdigcloud-config -o yaml | grep -i api.url: | head -1 | awk '{print$2}')
        fi
       
        # Check that the API_KEY for the Super User is valid and exit 
        CURL_OUT=$(curl -fks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/license" >/dev/null 2>&1) && RETVAL=$? && error=0 || { RETVAL=$? && error=1; }
        if [[ ${error} -eq 1 ]]; then
            echo "The API_KEY supplied is Unauthorized.  Please check and try again.  Return Code: ${RETVAL}"
            exit 1
        fi

        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/license" >> ${LOG_DIR}/license.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customer/1/streamsnapSettings" >> ${LOG_DIR}/streamSnap_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customers/1/snapshotSettings" >> ${LOG_DIR}/snapshot_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customer/1/fastPathSettings" >> ${LOG_DIR}/fastPath_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customer/1/indexSettings" >> ${LOG_DIR}/index_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customer/1/planSettings" >> ${LOG_DIR}/plan_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/admin/customer/1/dataRetentionSettings" >> ${LOG_DIR}/dataRetention_settings.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/agents/connected" >> ${LOG_DIR}/agents-connected.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/v2/users/light" >> ${LOG_DIR}/users.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/v2/teams/light" >> ${LOG_DIR}/teams.json
        curl -ks -H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" "${API_URL}/api/alerts" >> ${LOG_DIR}/alerts.json

        if [[ $OSTYPE == 'darwin'* ]]; then
            TO_EPOCH_TIME=$(date -jf "%H:%M:%S" $(date +%H):00:00 +%s)
        else
            TO_EPOCH_TIME=$(date -d "$(date +%H):00:00" +%s)
        fi
        FROM_EPOCH_TIME=$((TO_EPOCH_TIME-86400))
        METRICS=("syscall.count" "dragent.analyzer.sr" "container.count" "dragent.analyzer.n_drops_buffer" "dragent.analyzer.n_evts")
        DEFAULT_SEGMENT="host.hostName"
        SYSCALL_SEGMENTS=("host.hostName" "proc.name")

        mkdir -p ${LOG_DIR}/metrics
        for metric in ${METRICS[@]}; do
            if [ "${metric}" == "syscall.count" ]; then
                for segment in ${SYSCALL_SEGMENTS[@]}; do
                    get_metrics "${metric}" "${segment}"
                done
            else
                get_metrics "${metric}" "${DEFAULT_SEGMENT}"
            fi
        done

        get_agent_version_metric_limits
    fi

    # Configure kubectl command if labels are set
    if [[ -z ${LABELS} ]]; then
        SYSDIGCLOUD_PODS=$(kubectl ${KUBE_OPTS} get pods --no-headers | awk '{ print $1 }')
    else
        SYSDIGCLOUD_PODS=$(kubectl ${KUBE_OPTS} -l "role in (${LABELS})" get pods --no-headers | awk '{ print $1 }')
    fi

    echo "Using namespace ${NAMESPACE}"
    echo "Using context ${CONTEXT}"

    # Collect container logs for each pod
    if [[ "${SKIP_LOGS}" == "false" ]]; then
        echo "Gathering Logs from ${NAMESPACE} pods"
        command='tar czf - /logs/ /opt/draios/ /var/log/sysdigcloud/ /var/log/cassandra/ /tmp/redis.log /var/log/redis-server/redis.log /var/log/mysql/error.log /opt/prod.conf 2>/dev/null || true'
        for pod in ${SYSDIGCLOUD_PODS}; do
            echo "Getting support logs for ${pod}"
            mkdir -p ${LOG_DIR}/${pod}
            containers=$(kubectl ${KUBE_OPTS} get pod ${pod} -o json | jq -r '.spec.containers[].name' || echo "")
            for container in ${containers}; do
                kubectl ${KUBE_OPTS} logs ${pod} -c ${container} ${SINCE_OPTS} > ${LOG_DIR}/${pod}/${container}-kubectl-logs.txt || true
                echo "Execing into ${container}"
                kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- bash -c "echo" >/dev/null 2>&1 && RETVAL=$? || RETVAL=$? && true
                kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- sh -c "echo" >/dev/null 2>&1 && RETVAL1=$? || RETVAL1=$? && true
                if [ $RETVAL -eq 0 ]; then
                    kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- bash -c "${command}" > ${LOG_DIR}/${pod}/${container}-support-files.tgz || true
                elif [ $RETVAL1 -eq 0 ]; then
                    kubectl ${KUBE_OPTS} exec ${pod} -c ${container} -- sh -c "${command}" > ${LOG_DIR}/${pod}/${container}-support-files.tgz || true
                else
                    echo "Skipping log gathering for ${pod}"
                fi
            done
        done
    fi

    echo "Gathering pod descriptions"
    for pod in ${SYSDIGCLOUD_PODS}; do
        echo "Getting pod description for ${pod}"
        mkdir -p ${LOG_DIR}/${pod}
        kubectl ${KUBE_OPTS} get pod ${pod} -o json > ${LOG_DIR}/${pod}/kubectl-describe.json
    done

    #Collect Describe Node Output
    echo "Collecting node information"
    kubectl ${KUBE_OPTS} describe nodes | tee -a ${LOG_DIR}/describe_node_output.log || echo "No permission to describe nodes!"

    NODES=$(kubectl ${KUBE_OPTS} get nodes --no-headers | awk '{print $1}') && RETVAL=0 || { RETVAL=$? && echo "No permission to get nodes!"; }
    if [[ "${RETVAL}" == "0" ]]; then
        mkdir -p ${LOG_DIR}/nodes
        for node in ${NODES[@]}; do
            kubectl ${KUBE_OPTS} get node ${node} -ojson > ${LOG_DIR}/nodes/${node}-kubectl.json
        done
        unset RETVAL
    fi

    #Collect PV info
    kubectl ${KUBE_OPTS} get pv | grep sysdig | tee -a ${LOG_DIR}/pv_output.log || echo "No permission to get PersistentVolumes"
    kubectl ${KUBE_OPTS} get pvc | grep sysdig | tee -a ${LOG_DIR}/pvc_output.log
    kubectl ${KUBE_OPTS} get storageclass | tee -a ${LOG_DIR}/sc_output.log || echo "No permission to get StorageClasses"

    # Get info on deployments, statefulsets, persistentVolumeClaims, daemonsets, and ingresses
    echo "Gathering Manifest Information"
    for object in svc deployment sts pvc daemonset ingress replicaset networkpolicy
    do
        items=$(kubectl ${KUBE_OPTS} get ${object} -o jsonpath="{.items[*]['metadata.name']}")
        mkdir -p ${LOG_DIR}/${object}
        for item in ${items}; do
            kubectl ${KUBE_OPTS} get ${object} ${item} -o json > ${LOG_DIR}/${object}/${item}-kubectl.json
        done
    done

    # Fetch container density information
    num_nodes=0
    num_pods=0
    num_running_containers=0
    num_total_containers=0

    printf "%-30s %-10s %-10s %-10s %-10s\n" "Node" "Pods" "Running Containers" "Total Containers" >> ${LOG_DIR}/container_density.txt
    for node in $(kubectl ${KUBE_OPTS} get nodes --no-headers -o custom-columns=node:.metadata.name); do
        total_pods=$(kubectl ${KUBE_OPTS} get pods -A --no-headers -o wide | grep ${node} |wc -l |xargs)
        running_containers=$( kubectl ${KUBE_OPTS} get pods -A --no-headers -o wide |grep ${node} |awk '{print $3}' |cut -f 1 -d/ | awk '{ SUM += $1} END { print SUM }' |xargs)
        total_containers=$( kubectl get ${KUBE_OPTS} pods -A --no-headers -o wide |grep ${node} |awk '{print $3}' |cut -f 2 -d/ | awk '{ SUM += $1} END { print SUM }' |xargs)
        printf "%-30s %-15s %-20s %-10s\n" "${node}" "${total_pods}" "${running_containers}" "${total_containers}" >> ${LOG_DIR}/container_density.txt
        num_nodes=$((num_nodes+1))
        num_pods=$((num_pods+${total_pods}))
        num_running_containers=$((num_running_containers+${running_containers}))
        num_total_containers=$((num_total_containers+${total_containers}))
    done

    printf "\nTotals\n-----\n" >> ${LOG_DIR}/container_density.txt
    printf "Nodes: ${num_nodes}\n" >> ${LOG_DIR}/container_density.txt
    printf "Pods: ${num_pods}\n" >> ${LOG_DIR}/container_density.txt
    printf "Running Containers: ${num_running_containers}\n" >> ${LOG_DIR}/container_density.txt
    printf "Containers: ${num_total_containers}\n" >> ${LOG_DIR}/container_density.txt

    # Fetch Cassandra Nodetool output
    echo "Fetching Cassandra statistics"
    for pod in $(kubectl ${KUBE_OPTS} get pod -l role=cassandra --no-headers| awk '{print $1}')
    do
        mkdir -p ${LOG_DIR}/cassandra/${pod}
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool info | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_info.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool status | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_status.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool getcompactionthroughput | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_getcompactionthroughput.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool cfstats | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_cfstats.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool cfhistograms draios message_data10 | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_cfhistograms.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool proxyhistograms | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_proxyhistograms.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool tpstats | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_tpstats.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- nodetool compactionstats | tee -a ${LOG_DIR}/cassandra/${pod}/nodetool_compactionstats.log
    done

    echo "Fetching Elasticsearch health info"
    # CHECK HERE IF THE TLS ENV VARIABLE IS SET IN ELASTICSEARCH, AND BUILD THE CURL COMMAND OUT
    ELASTIC_POD=$(kubectl ${KUBE_OPTS} get pods -l role=elasticsearch --no-headers | head -1 | awk '{print $1}') || true

    if [ ! -z ${ELASTIC_POD} ]; then
        ELASTIC_IMAGE=$(kubectl ${KUBE_OPTS} get pod ${ELASTIC_POD} -ojsonpath='{.spec.containers[?(@.name == "elasticsearch")].image}' | awk -F '/' '{print $NF}' | cut -f 1 -d ':') || true

        if [[ ${ELASTIC_IMAGE} == "opensearch"* ]]; then
            CERTIFICATE_DIRECTORY="/usr/share/opensearch/config"
            ELASTIC_TLS="true"
        else
            CERTIFICATE_DIRECTORY="/usr/share/elasticsearch/config"
            ELASTIC_TLS=$(kubectl ${KUBE_OPTS} exec ${ELASTIC_POD} -c elasticsearch -- env | grep -i ELASTICSEARCH_TLS_ENCRYPTION) || true
            if [[ ${ELASTIC_TLS} == *"ELASTICSEARCH_TLS_ENCRYPTION=true"* ]]; then
                ELASTIC_TLS="true"
            fi
        fi

        if [[ ${ELASTIC_TLS} == "true" ]]; then
            ELASTIC_CURL="curl -s --cacert ${CERTIFICATE_DIRECTORY}/root-ca.pem https://\${ELASTICSEARCH_ADMINUSER}:\${ELASTICSEARCH_ADMIN_PASSWORD}@\$(hostname):9200"
        else
            ELASTIC_CURL='curl -s -k http://$(hostname):9200'
        fi

        for pod in $(kubectl ${KUBE_OPTS} get pods -l role=elasticsearch --no-headers | awk '{print $1}')
        do
            mkdir -p ${LOG_DIR}/elasticsearch/${pod}

            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- /bin/bash -c "${ELASTIC_CURL}/_cat/health" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_health.log || true

            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- /bin/bash -c "${ELASTIC_CURL}/_cat/indices" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_indices.log || true

            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- /bin/bash -c "${ELASTIC_CURL}/_cat/nodes?v" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_nodes.log || true

            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- /bin/bash -c "${ELASTIC_CURL}/_cluster/allocation/explain?pretty" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_index_allocation.log || true

            echo "Fetching ElasticSearch SSL Certificate Expiration Dates"
            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- openssl x509 -in ${CERTIFICATE_DIRECTORY}/node.pem -noout -enddate | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_node_pem_expiration.log || true
            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- openssl x509 -in ${CERTIFICATE_DIRECTORY}/admin.pem -noout -enddate | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_admin_pem_expiration.log || true
            kubectl ${KUBE_OPTS} exec ${pod}  -c elasticsearch -- openssl x509 -in ${CERTIFICATE_DIRECTORY}/root-ca.pem -noout -enddate | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_root_ca_pem_expiration.log || true


            echo "Fetching Elasticsearch Index Versions"
            kubectl ${KUBE_OPTS} exec ${pod} -c elasticsearch -- bash -c "${ELASTIC_CURL}/_all/_settings/index.version\*?pretty" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_index_versions.log || true

            echo "Checking Used Elasticsearch Storage - ${pod}"
            mountpath=$(kubectl ${KUBE_OPTS} get sts sysdigcloud-elasticsearch -ojsonpath='{.spec.template.spec.containers[].volumeMounts[?(@.name == "data")].mountPath}')
            if [ ! -z $mountpath ]; then
               kubectl ${KUBE_OPTS} exec ${pod} -c elasticsearch -- du -ch ${mountpath} | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_storage.log || true
           else
              printf "Error getting ElasticSearch ${pod} mount path\n" | tee -a ${LOG_DIR}/elasticsearch/${pod}/elasticsearch_storage.log
           fi
        done
    else
        echo "Unable to fetch ElasticSearch pod to gather health info!"
    fi

    # Fetch Cassandra storage info
    for pod in $(kubectl ${KUBE_OPTS} get pods -l role=cassandra --no-headers | awk '{print $1}')
    do
        echo "Checking Used Cassandra Storage - ${pod}"
        mkdir -p ${LOG_DIR}/cassandra/${pod}
        printf "${pod}\n" | tee -a ${LOG_DIR}/cassandra/${pod}/cassandra_storage.log
        mountpath=$(kubectl ${KUBE_OPTS} get sts sysdigcloud-cassandra -ojsonpath='{.spec.template.spec.containers[].volumeMounts[?(@.name == "data")].mountPath}')
        if [ ! -z $mountpath ]; then
            kubectl ${KUBE_OPTS} exec -it ${pod} -c cassandra -- du -ch ${mountpath} | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/cassandra/${pod}/cassandra_storage.log || true
       else
          printf "Error getting Cassandra ${pod} mount path\n" | tee -a ${LOG_DIR}/cassandra/${pod}/cassandra_storage.log
       fi
    done

    # Fetch postgresql storage info
    for pod in $(kubectl ${KUBE_OPTS} get pods -l role=postgresql --no-headers  | awk '{print $1}')
    do
        echo "Checking Used PostgreSQL Storage - ${pod}"
        mkdir -p ${LOG_DIR}/postgresql/${pod}
        printf "${pod}\n" | tee -a ${LOG_DIR}/postgresql/${pod}/postgresql_storage.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c postgresql -- du -ch /var/lib/postgresql | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/postgresql/${pod}/postgresql_storage.log || true
    done

    # Fetch mysql storage info
    for pod in $(kubectl ${KUBE_OPTS} get pods -l role=mysql --no-headers | awk '{print $1}')
    do
        echo "Checking Used MySQL Storage - ${pod}"
        mkdir -p ${LOG_DIR}/mysql/${pod}
        printf "${pod}\n" | tee -a ${LOG_DIR}/mysql/${pod}/mysql_storage.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c mysql -- du -ch /var/lib/mysql | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/mysql/${pod}/mysql_storage.log || true
    done

    # Fetch kafka storage info
    for pod in $(kubectl ${KUBE_OPTS} get pods -l role=cp-kafka --no-headers | awk '{print $1}')
    do
        echo "Checking Used Kafka Storage - ${pod}"
        mkdir -p ${LOG_DIR}/kafka/${pod}
        printf "${pod}\n" | tee -a ${LOG_DIR}/kafka/${pod}/kafka_storage.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c broker -- du -ch /opt/kafka/data | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/kafka/${pod}/kafka_storage.log || true
    done

    # Fetch zookeeper storage info
    for pod in $(kubectl ${KUBE_OPTS} get pods -l role=zookeeper --no-headers | awk '{print $1}')
    do
        echo "Checking Used Zookeeper Storage - ${pod}"
        mkdir -p ${LOG_DIR}/zookeeper/${pod}
        printf "${pod}\n" | tee -a ${LOG_DIR}/zookeeper/${pod}/zookeeper_storage.log
        kubectl ${KUBE_OPTS} exec -it ${pod} -c server -- du -ch /var/lib/zookeeper/data | grep -i total | awk '{printf "%-13s %10s\n",$1,$2}' | tee -a ${LOG_DIR}/zookeeper/${pod}/zookeeper_storage.log || true
    done

    # Collect the sysdigcloud-config configmap, and write to the log directory
    echo "Fetching the sysdigcloud-config ConfigMap"
    kubectl ${KUBE_OPTS} get configmap sysdigcloud-config -o yaml | grep -v password | grep -v apiVersion > ${LOG_DIR}/config.yaml || true

    # Generate the bundle name, create a tarball, and remove the temp log directory
    BUNDLE_NAME=$(date +%s)_sysdig_cloud_support_bundle.tgz
    echo "Creating the ${BUNDLE_NAME} archive now"
    tar czf ${BUNDLE_NAME} ${LOG_DIR}
    rm -rf ${LOG_DIR}

    echo "Support bundle generated:" ${BUNDLE_NAME}
}

parse_commandline "$@"
main
