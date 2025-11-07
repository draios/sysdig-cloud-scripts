#!/bin/bash

namespace=$1
podName=$2

function initVar()
{
  # Ensure namespace is provided
  if [ -z "$namespace" ]; then
    echo "Error: namespace is a required parameter."
    echo "Usage: $0 namespace [podName]"
    exit 1
  fi

  DEST_DIR=$(pwd)
  SYSDIG_SUPPORT_DIR="sysdig-support"
  [ ! -d "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}" ] && mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}"

  ACTIVITY_LOG="${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/activity.log"
  function log_activity() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $MESSAGE" >> "${ACTIVITY_LOG}"
  }
  echo "Sysdig Support Script Activity Log - $(date)" > "${ACTIVITY_LOG}"
  log_activity "Initialized activity log and created/confirmed output folder."

  local CURR_DATE=$(date '+%Y-%m-%d_%H%M%S')
  ARCHIVE_NAME="support-util-${CURR_DATE}.tar.gz"
  LABEL_IDENTIFIER="app.kubernetes.io/instance"
  
    #DO NOT CHANGE THE SECTION BELOW, UNLESS YOU'RE USING CUSTOM NAMES
  SYSDIG_KSPMA_CONTAINER_NAME="sysdig-kspm-analyzer"
  SYSDIG_HS_CONTAINER_NAME="sysdig-host-scanner"
  SYSDIG_RS_CONTAINER_NAME="sysdig-runtime-scanner"
  SYSDIG_AGENT_CONTAINER_NAME="sysdig"
  SYSDIG_CS_DIR="clusterShield"
  AGENT_LOG_DIR="opt/draios/logs/"
  AGENT_DRAGENT_DIR="opt/draios/etc/kubernetes/config/..data"
  IS_AIRGAPPED=false
  SYSDIG_CS_ENDPOINT="healthz"
  SYSDIG_CS_MONITORING_PORT=8080
  ERR_RC_TAR=8
  ERR_RC_CURL=9

[ ! -d "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}" ] && mkdir -p ${DEST_DIR}/${SYSDIG_SUPPORT_DIR}
  
export DEST_DIR
export ARCHIVE_NAME
export ERR_RC_TAR
export ERR_RC_CURL
export AGENT_LOG_DIR
export SYSDIG_CS_DIR
export IS_AIRGAPPED

  printf "All the data will be saved using the path ${DEST_DIR}/${SYSDIG_SUPPORT_DIR}\n"
  log_activity "Data directory set to ${DEST_DIR}/${SYSDIG_SUPPORT_DIR}"

  printf "Please put your executable to access your k8s cluster, kubectl or oc\n"
  read k8sCmd
  log_activity "User selected Kubernetes CLI: ${k8sCmd}"

  export k8sCmd

SYSDIG_APP_NAME=$($k8sCmd get pods -n $namespace -o go-template='{{ range .items }}{{ index .metadata.labels "'${LABEL_IDENTIFIER}'" }}{{ "\n" }}{{end}}'| head -1)
SYSDIG_AGENT_PREFIX="${SYSDIG_APP_NAME}-agent-[a-zA-Z0-9]|${SYSDIG_APP_NAME}-shield-host-[a-zA-Z0-9]|${SYSDIG_APP_NAME}-host-[a-zA-Z0-9]|${SYSDIG_APP_NAME}-[a-zA-Z0-9]"
SYSDIG_CS_PREFIX="${SYSDIG_APP_NAME}-clustershield-[a-zA-Z0-9]|${SYSDIG_APP_NAME}-shield-cluster-[a-zA-Z0-9]|${SYSDIG_APP_NAME}-cluster-[a-zA-Z0-9]"
SYSDIG_CS_SH_PREFIX="${SYSDIG_APP_NAME}-cluster-[a-zA-Z0-9]"
SYSDIG_NA_PREFIX="${SYSDIG_APP_NAME}-node-analyzer-[a-zA-Z0-9]"
SYSDIG_KSPMC_PREFIX="${SYSDIG_APP_NAME}-kspmcollector-[a-zA-Z0-9]"
export SYSDIG_AGENT_PREFIX
export SYSDIG_CS_PREFIX
  
  log_activity "initVar completed."
}

function disclaimer()
{
  log_activity "Displayed disclaimer to user."
  printf "This script will collect some information from your cluster, no changes will be made.\nPlease ensure that KUBECTL or OC executable are available in your PATH.\n"
  printf "Please ensure that you have access, at least, to the namespace where sysdig pods are currently running.\n"
  printf "Please press Enter to continue.\n"
  read go
  log_activity "User confirmed disclaimer and continued."
  clear
  log_activity "Screen cleared after disclaimer."
}

function isAirgapped()
{

printf "The script use a curl command to upload the archive file created into your case\n"
printf "Please put y if your environment has restrictions on internet access or no internet access. \n Put n if your env do not have any kind of restrictions for internet access\n"
read answer
clear

}

function collectArtifacts()
{
  log_activity "Starting collectArtifacts (namespace: ${namespace}, pod: ${podName:-ALL})"
  if [ -z "${podName}" ]; then
    printf "Getting all sysdig pods configuration, this could take a while\n"
    log_activity "Collecting cluster info (version output)."
    $k8sCmd version -o json > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/cluster_info.json"
    log_activity "Collected cluster_info.json."

    $k8sCmd get po --sort-by='.status.containerStatuses[0].restartCount' --no-headers -n "${namespace}" -o wide > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/running_pods.txt"
    log_activity "Saved running_pods.txt."

    if [[ "$k8sCmd" == "oc" ]]; then
      $k8sCmd adm top pod -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/top_pods.txt"
      log_activity "Collected pod resource usage (oc mode)."
    else
      $k8sCmd top pod -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/top_pods.txt" || printf "Metrics server not installed or ready, moving forward\n"
      log_activity "Collected pod resource usage (kubectl mode)."
    fi

    $k8sCmd describe po -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/describe_pods.txt"
    $k8sCmd get cm -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/configmap.txt"
    $k8sCmd get ds -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/daemonset.txt"
    $k8sCmd get deploy -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/deployment.txt"
    log_activity "Saved configmap.txt, daemonset.txt, deployment.txt, describe_pods.txt"

    $k8sCmd describe nodes > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/nodes.txt"
    log_activity "Saved nodes.txt."

    printf "Configuration collection completed for all Sysdig pods\n"
    log_activity "Configuration collection completed for all pods."
  else
    printf "Getting the pod configuration for the pod ${podName}\n"
    log_activity "Collecting cluster info for specific pod (${podName})."
    $k8sCmd version -o json > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/cluster_info.json"
    if [[ "$k8sCmd" == "oc" ]]; then
      $k8sCmd adm top pod -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/top_pods.txt"
      log_activity "Collected pod resource usage (oc mode)."
    else
      $k8sCmd top pod -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/top_pods.txt" || printf "Metrics server not installed or ready, moving forward\n"
      log_activity "Collected pod resource usage (kubectl mode)."
    fi
    $k8sCmd get po ${podName} -n "${namespace}" -o wide > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/${podName}_node.txt"
    log_activity "Saved ${podName}_node.txt."
    $k8sCmd describe po ${podName} -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/describe_pods_${podName}.txt"
    log_activity "Saved describe_pods_${podName}.txt."
    $k8sCmd get cm -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/configmap.txt"
    $k8sCmd get ds -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/daemonset.txt"
    $k8sCmd get deploy -o yaml -n "${namespace}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/deployment.txt"
    log_activity "Saved configmap.txt, daemonset.txt, deployment.txt."
    $k8sCmd describe nodes > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/nodes.txt"
    log_activity "Saved nodes.txt."
    printf "Configuration collection completed for pod ${podName}\n"
    log_activity "Configuration collection completed for pod ${podName}."
  fi

  printf "Collecting cluster object counts\n"
  deployments=$($k8sCmd get deployments --all-namespaces --no-headers 2>/dev/null | wc -l)
  replicasets=$($k8sCmd get replicasets --all-namespaces --no-headers 2>/dev/null | wc -l)
  namespaces=$($k8sCmd get namespaces --no-headers 2>/dev/null | wc -l)
  configmaps=$($k8sCmd get configmaps --all-namespaces --no-headers 2>/dev/null | wc -l)
  pods=$($k8sCmd get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
  {
    echo "Cluster Object Counts:"
    echo "-----------------------"
    echo "Deployments : $deployments"
    echo "ReplicaSets : $replicasets"
    echo "Namespaces : $namespaces"
    echo "ConfigMaps : $configmaps"
    echo "Pods : $pods"
  } > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/cluster_object_counts.txt"
  log_activity "Saved cluster_object_counts.txt with deployments:$deployments, replicasets:$replicasets, namespaces:$namespaces, configmaps:$configmaps, pods:$pods."
  CS_POD_IP=`cat ${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/running_pods.txt|grep -E ${SYSDIG_CS_PREFIX}|head -1|awk '{print $6}'`
  log_activity "collectArtifacts completed."
}

function getLogs()
{
  log_activity "Starting getLogs (namespace: ${namespace}, pod: ${podName:-ALL})"
  local csAttempt=0
  local drAgentAttempt=0
  if [ -z "${podName}" ]; then
    printf "Getting all sysdig logs, this could take a while\n"
    for pod in $(awk '{print $1}' < "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/running_pods.txt"); do
      printf "Getting log of pod ${pod}\n"
      log_activity "Attempting log collection for pod ${pod}."
      if [[ $pod != *"clustershield"* && $pod != *"node-analyzer"* && $pod != *"shield-cluster"* && $pod != *"kspmcollector"* && $pod =~ $SYSDIG_AGENT_PREFIX ]]; then
        mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}"
        $k8sCmd -n "${namespace}" cp "$pod:${AGENT_LOG_DIR}." "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}" 2>/dev/null
        if [ $? -eq 0 ]; then
          log_activity "Copied agent log files for pod ${pod}."
        else
          log_activity "ERROR: Failed to copy logs for pod ${pod} (possibly recycled)."
        fi
        if [[ $CS_POD_IP != "" && $csAttempt -eq 0 ]]; then
          log_activity "Tryng to perform curl against cluster shield health endpoint"
           $k8sCmd exec $pod -n "${namespace}" -- curl http://${CS_POD_IP}:${SYSDIG_CS_MONITORING_PORT}/${SYSDIG_CS_ENDPOINT} > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/csFeaturesStatus.txt" 2>/dev/null || printf "Unable to call CS health endpoint, moving forward\n"
           ((csAttempt++))
        fi
        if [[ $drAgentAttempt -eq 0 ]]; then
          log_activity "Getting dragent.yaml from pod ${pod}"
          $k8sCmd -n "${namespace}" cp "$pod:${AGENT_DRAGENT_DIR}/dragent.yaml" "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/dragent.yaml" 2>/dev/null
          log_activity "Getting dragent.yaml from pod ${pod} completed!"
          ((drAgentAttempt++))
        fi
        
      fi
      if [[ $pod =~ $SYSDIG_CS_PREFIX || $pod =~ $SYSDIG_CS_SH_PREFIX ]]; then
        mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${SYSDIG_CS_DIR}"
        $k8sCmd -n "${namespace}" logs "$pod" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${SYSDIG_CS_DIR}/${pod}.log" 2>/dev/null
        if [ $? -eq 0 ]; then
          log_activity "Collected cluster shield log for pod ${pod}."
        else
          log_activity "ERROR: Failed to collect cluster shield log for pod ${pod} (pod not found)."
        fi
      fi
      if [[ $pod =~ $SYSDIG_NA_PREFIX ]]; then
        mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs"
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_KSPMA_CONTAINER_NAME}" > /dev/null 2>&1 && \
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_KSPMA_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}_${SYSDIG_KSPMA_CONTAINER_NAME}.log" && \
        log_activity "Collected kspm-analyzer logs for pod ${pod}." || \
        log_activity "kspm-analyzer not installed for pod ${pod}."
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_HS_CONTAINER_NAME}" > /dev/null 2>&1 && \
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_HS_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}_${SYSDIG_HS_CONTAINER_NAME}.log" && \
        log_activity "Collected host-scanner logs for pod ${pod}." || \
        log_activity "host-scanner not installed for pod ${pod}."
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_RS_CONTAINER_NAME}" > /dev/null 2>&1 && \
        $k8sCmd -n "${namespace}" logs "${pod}" -c "${SYSDIG_RS_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}_${SYSDIG_RS_CONTAINER_NAME}.log" && \
        log_activity "Collected runtime-scanner logs for pod ${pod}." || \
        log_activity "runtime-scanner not installed for pod ${pod}."
      fi
      if [[ $pod =~ $SYSDIG_KSPMC_PREFIX ]]; then
        mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs"
        $k8sCmd -n "${namespace}" logs "${pod}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${pod}.log" 2>/dev/null
        if [ $? -eq 0 ]; then
          log_activity "Collected kspmcollector log for pod ${pod}."
        else
          log_activity "ERROR: Failed to collect kspmcollector log for pod ${pod} (pod not found)."
        fi
      fi
    done
    log_activity "Log collection completed for all pods."
  else
    log_activity "Attempting log collection for pod ${podName}."
    if [[ $podName != *"clustershield"* && $podName != *"node-analyzer"* && $podName != *"shield-cluster"* && $podName != *"kspmcollector"* && $podName =~ $SYSDIG_AGENT_PREFIX ]]; then
      printf "Collecting log for pod ${podName}\n"
      mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}"
      $k8sCmd -n "${namespace}" cp "${podName}:${AGENT_LOG_DIR}." "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}" 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod ${podName}\n"
        log_activity "Collected agent log for pod ${podName}."
      else
        log_activity "ERROR: Failed to collect agent log for pod ${podName} (possibly recycled)."
      fi
    fi
    if [[ $podName =~ $SYSDIG_CS_PREFIX || $podName =~ $SYSDIG_CS_SH_PREFIX ]]; then
      printf "Collecting log for pod ${podName}\n"
      mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${SYSDIG_CS_DIR}"
      $k8sCmd -n "${namespace}" logs "${podName}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${SYSDIG_CS_DIR}/${podName}.log" 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod ${podName}\n"
        log_activity "Collected cluster shield log for pod ${podName}."
      else
        log_activity "ERROR: Failed to collect cluster shield log for pod ${podName} (pod not found)."
      fi
    fi
    if [[ $podName =~ $SYSDIG_NA_PREFIX ]]; then
      printf "Collecting log for pod ${podName}\n"
      mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs"
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_KSPMA_CONTAINER_NAME}" > /dev/null 2>&1 && \
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_KSPMA_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}_${SYSDIG_KSPMA_CONTAINER_NAME}.log" && \
      log_activity "Collected kspm-analyzer log for pod ${podName}." || \
      log_activity "kspm-analyzer not installed for pod ${podName}."
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_HS_CONTAINER_NAME}" > /dev/null 2>&1 && \
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_HS_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}_${SYSDIG_HS_CONTAINER_NAME}.log" && \
      log_activity "Collected host-scanner log for pod ${podName}." || \
      log_activity "host-scanner not installed for pod ${podName}."
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_RS_CONTAINER_NAME}" > /dev/null 2>&1 && \
      $k8sCmd -n "${namespace}" logs "${podName}" -c "${SYSDIG_RS_CONTAINER_NAME}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}_${SYSDIG_RS_CONTAINER_NAME}.log" && \
      log_activity "Collected runtime-scanner log for pod ${podName}." || \
      log_activity "runtime-scanner not installed for pod ${podName}."
      printf "Log collected for pod ${podName}\n"
    fi
    if [[ $podName =~ $SYSDIG_KSPMC_PREFIX ]]; then
      printf "Collecting log for pod ${podName}\n"
      mkdir -p "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs"
      $k8sCmd -n "${namespace}" logs "${podName}" > "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/logs/${podName}.log" 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod ${podName}\n"
        log_activity "Collected kspmcollector log for pod ${podName}."
      else
        log_activity "ERROR: Failed to collect kspmcollector log for pod ${podName} (pod not found)."
      fi
    fi
    log_activity "Log collection completed for pod ${podName}."
  fi
  log_activity "getLogs completed."
}

function compressAndUpload()
{
  cd "${DEST_DIR}/${SYSDIG_SUPPORT_DIR}"
  printf "Creating archive file ${ARCHIVE_NAME}\n"
  log_activity "Starting archive creation: ${ARCHIVE_NAME}."
  errorMessage=$(tar czf "${ARCHIVE_NAME}" * 2>&1)
  if [ $? -eq 0 ]; then
    printf "Archive file created successfully, ready for upload!\n"
    log_activity "Archive ${ARCHIVE_NAME} created successfully."
  else
    printf "Something went wrong\n"
    printf "%s\n" "$errorMessage"
    log_activity "Failed to create archive (${ARCHIVE_NAME}): $errorMessage"
    exit "${ERR_RC_TAR}"
  fi
if [ $answer == "y" ];
  then
  printf "The archive has been saved in the path ${DEST_DIR}/${SYSDIG_SUPPORT_DIR} , archive name is ${ARCHIVE_NAME}\n"
  IS_AIRGAPPED="true"
  cleanArtifacts $IS_AIRGAPPED
  printf "Script execution completed, exit \n"
  exit 0
 else

  printf "Please put the S3 link provided by Sysdig Support, the script will upload the archive on the case.\n"
  read SYSDIG_UPLOAD_URL
  log_activity "User provided S3 upload URL: ${SYSDIG_UPLOAD_URL}"

  printf "The status of the upload will not be shown, please be patient\n"
  log_activity "Uploading ${ARCHIVE_NAME} to S3 (${SYSDIG_UPLOAD_URL})..."
  httpRetCode=$(curl -s -S -o /dev/null -w "%{http_code}" -X PUT --url "${SYSDIG_UPLOAD_URL}" -H "Content-Disposition: attachment; filename=${ARCHIVE_NAME}" -T "${ARCHIVE_NAME}")
  if [ $httpRetCode -eq 200 ]; then
    printf "Archive file uploaded successfully!\n"
    log_activity "Archive uploaded successfully to S3."
    cleanArtifacts
  else
    printf "Something went wrong\n"
    log_activity "S3 upload failed with curl exit code $httpRetCode"
    exit "${ERR_RC_CURL}"
  fi

  printf "Script execution completed!\n"
  log_activity "Script execution completed."
fi
}

function cleanArtifacts
{

printf "Cleanup started\n"
log_activity "Script Cleanup Started"

cd ${DEST_DIR}/${SYSDIG_SUPPORT_DIR}

printf "Removing cluster_info.json file\n"
rm cluster_info.json || printf "File not found, or not enough privileges, moving forward\n"
printf "Removing txt file\n"
  for i in $(ls *.txt); do
    printf "removing $i \n"
    rm $i
  done
  if [ $IS_AIRGAPPED == "false" ];
    then
    printf "Removing archive file $ARCHIVE_NAME\n"
    rm $ARCHIVE_NAME
  fi

printf "Removing the logs directory\n"
rm -fr logs

printf "Cleanup completed!\n"
log_activity "Script Cleanup completed"
}

# Main workflow
initVar
disclaimer
isAirgapped
collectArtifacts
getLogs
compressAndUpload
