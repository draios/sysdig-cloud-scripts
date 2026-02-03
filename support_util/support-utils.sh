#!/bin/bash

namespace=$1
podName=$2

function initVar()
{
  # Ensure namespace is provided
  if [ -z "$namespace" ]; then
    echo "Error: namespace is a required parameter."
    echo "Usage: $0 namespace [podName - optional]"
    exit 1
  fi

  DEST_DIR=$(pwd)
  SYSDIG_SUPPORT_DIR="sysdig-support"
  mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR

  ACTIVITY_LOG="${DEST_DIR}/${SYSDIG_SUPPORT_DIR}/activity.log"
  function log_activity() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $MESSAGE" >> "${ACTIVITY_LOG}"
  }
  echo "Sysdig Support Script Activity Log - $(date)" > "${ACTIVITY_LOG}"
  log_activity "Initialized activity log and created/confirmed output folder."

  local CURR_DATE=$(date '+%Y-%m-%d_%H%M%S')
  ARCHIVE_NAME="support-util-${CURR_DATE}.tar.gz"
  
  #DO NOT CHANGE THE SECTION BELOW, UNLESS YOU'RE USING CUSTOM NAMES
  SYSDIG_KSPM_IMAGE_NAME="kspm-analyzer"
  SYSDIG_HS_IMAGE_NAME="host-scanner"
  SYSDIG_RS_IMAGE_NAME="runtime-scanner"
  SYSDIG_KSPMA_CONTAINER_NAME="sysdig-kspm-analyzer"
  SYSDIG_HS_CONTAINER_NAME="sysdig-host-scanner"
  SYSDIG_RS_CONTAINER_NAME="sysdig-runtime-scanner"
  SYSDIG_AGENT_CONTAINER_NAME="sysdig"
  SYSDIG_NA_IMAGE_NAME="${SYSDIG_KSPM_IMAGE_NAME}|${SYSDIG_HS_IMAGE_NAME}|${SYSDIG_RS_IMAGE_NAME}"
  SYSDIG_AGENT_IMAGE_NAME="agent-slim|agent"
  SYSDIG_CS_IMAGE_NAME="cluster-shield"
  SYSDIG_KSPM_COLLECTOR_IMAGE_NAME="kspm-collector"
  SYSDIG_CS_DIR="clusterShield"
  AGENT_LOG_DIR="opt/draios/logs/"
  AGENT_DRAGENT_DIR="opt/draios/etc/kubernetes/config/..data"
  IS_AIRGAPPED=false
  SYSDIG_CS_ENDPOINT="healthz"
  SYSDIG_CS_MONITORING_PORT=8080
  SYSDIG_AGENT_IMMUTABLE_LABEL="app.kubernetes.io/name"
  SYSDIG_KSPM_COLLECTOR_IMMUTABLE_LABEL="app.kubernetes.io/instance"
  SYSDIG_NA_IMMUTABLE_LABEL="app.kubernetes.io/instance"
  SYSDIG_SHIELD_IMMUTABLE_LABEL="sysdig/component"
  SYSDIG_AGENT_KMODULE_NAME="agent-kmodule"
  SYSDIG_DS_NAME=""
  SYSDIG_DEPLOY_NAME=""
  JSONPATH_SEARCH="{range .items[*]}{.metadata.name}{'\t'}{.spec.template.spec.containers[0].image}{'\n'}{end}"
  AGENT_CP_RETRY=3
  DS_FIND_ATTEMPT_RETRY=1
  DP_FIND_ATTEMPT_RETRY=1
  DS_COUNTER_RETRY=0
  DP_COUNTER_RETRY=0
  ERR_RC_TAR=8
  ERR_RC_CURL=9
  ERR_RC_NOTHING_FOUND=10
  SYSDIG_AGENT_APP_NAME=""
  SYSDIG_NA_APP_NAME=""
  SYSDIG_CS_APP_NAME=""
  SYSDIG_KSPM_COLLECTOR_APP_NAME=""
  SYSDIG_AGENT_PREFIX=""
  SYSDIG_NA_PREFIX=""
  SYSDIG_CS_PREFIX=""
  SYSDIG_KSPMC_PREFIX=""
  
export DEST_DIR
export ARCHIVE_NAME
export ERR_RC_TAR
export ERR_RC_CURL
export AGENT_LOG_DIR
export SYSDIG_CS_DIR
export IS_AIRGAPPED

  printf "All the data will be saved using the path %s \n" "$DEST_DIR/$SYSDIG_SUPPORT_DIR"
  log_activity "Data directory set to $DEST_DIR/$SYSDIG_SUPPORT_DIR"

  printf "Please put your executable to access your k8s cluster, kubectl or oc\n"
  read k8sCmd
  log_activity "User selected Kubernetes CLI: $k8sCmd"

  export k8sCmd
  
  printf "Performing init vars\n"
while [[ -z $SYSDIG_DS_NAME ]] && [[ $DS_COUNTER_RETRY -le $DS_FIND_ATTEMPT_RETRY ]]; do
DS_LIST=$(
           $k8sCmd get ds -l "${SYSDIG_SHIELD_IMMUTABLE_LABEL}" -n $namespace -o=jsonpath="${JSONPATH_SEARCH}" 2>/dev/null 
           $k8sCmd get ds -l "${SYSDIG_AGENT_IMMUTABLE_LABEL}" -n $namespace -o=jsonpath="${JSONPATH_SEARCH}" 2>/dev/null
           $k8sCmd get ds -l "${SYSDIG_NA_IMMUTABLE_LABEL}" -n $namespace -o=jsonpath="${JSONPATH_SEARCH}" 2>/dev/null
         )
SYSDIG_DS_NAME=$(echo -e "${DS_LIST}" | grep . | sort | uniq)
log_activity "Ds name found $SYSDIG_DS_NAME"
(( DS_COUNTER_RETRY ++ ))
done

while [[ -z $SYSDIG_DEPLOY_NAME ]] && [[ $DP_COUNTER_RETRY -le $DP_FIND_ATTEMPT_RETRY ]]; do

DEPLOY_LIST=$(
              $k8sCmd get deploy -l "${SYSDIG_SHIELD_IMMUTABLE_LABEL}" -n $namespace -o=jsonpath="${JSONPATH_SEARCH}" 2>/dev/null
              $k8sCmd get deploy -l "${SYSDIG_KSPM_COLLECTOR_IMMUTABLE_LABEL}" -n $namespace -o=jsonpath="${JSONPATH_SEARCH}" 2>/dev/null
             );
SYSDIG_DEPLOY_NAME=$(echo -e "${DEPLOY_LIST}"|grep .|sort |uniq)
log_activity "Dp name found $SYSDIG_DEPLOY_NAME"
(( DP_COUNTER_RETRY ++ ))
done

if [[ -z $SYSDIG_DS_NAME ]] && [[ -z $SYSDIG_DEPLOY_NAME ]]; then
    printf -- "-----------------------------------------------------------------------\n"
    printf "RESULT: No Sysdig components found in namespace: '%s'\n" "$namespace"
    printf -- "-----------------------------------------------------------------------\n"
    printf "Possible reasons:\n"
    printf " 1. The namespace provided is incorrect.\n"
    printf " 2. The components (DaemonSet/Deployment) are not yet deployed.\n"
    printf " 3. The components are installed in a DIFFERENT namespace.\n\n"
    printf "NOTE: If your installation is split (e.g., Agent/Shield, Nodeanalyzer and/or ClusterShield in different\n"
    printf "namespaces), please run this script separately for each namespace.\n"
    printf -- "-----------------------------------------------------------------------"
  exit $ERR_RC_NOTHING_FOUND
fi


#split the app name and the image name
while IFS=$'\t' read -r APP_NAME IMAGE_NAME; do
    if [[ "$IMAGE_NAME" =~ $SYSDIG_AGENT_IMAGE_NAME ]]; then
        SYSDIG_AGENT_APP_NAME=$APP_NAME
        log_activity "Got agent, or shield, application name: $SYSDIG_AGENT_APP_NAME"
    fi
    if [[ "$IMAGE_NAME" =~ $SYSDIG_NA_IMAGE_NAME ]]; then
        SYSDIG_NA_APP_NAME=$APP_NAME
        log_activity "Got node-analyzer application name: $SYSDIG_NA_APP_NAME"
    fi
done <<< "${SYSDIG_DS_NAME}"



while IFS=$'\t' read -r APP_NAME IMAGE_NAME; do
    if [[ "$IMAGE_NAME" =~ $SYSDIG_CS_IMAGE_NAME ]]; then
        SYSDIG_CS_APP_NAME=$APP_NAME
        log_activity "Got clusterShield application name: $SYSDIG_CS_APP_NAME"
    fi
    if [[ "$IMAGE_NAME" =~ $SYSDIG_KSPM_COLLECTOR_IMAGE_NAME ]]; then
        SYSDIG_KSPM_COLLECTOR_APP_NAME=$APP_NAME
        log_activity "Got kspmcollector application name: $SYSDIG_KSPM_COLLECTOR_APP_NAME"
    fi
done <<< "${SYSDIG_DEPLOY_NAME}"

[[ -n "${SYSDIG_AGENT_APP_NAME//[[:space:]]/}" ]] && export SYSDIG_AGENT_PREFIX="${SYSDIG_AGENT_APP_NAME}-[a-zA-Z0-9]{5}$"
[[ -n "${SYSDIG_CS_APP_NAME//[[:space:]]/}" ]] && export SYSDIG_CS_PREFIX="${SYSDIG_CS_APP_NAME}-[a-zA-Z0-9]"
[[ -n "${SYSDIG_NA_APP_NAME//[[:space:]]/}" ]] && export SYSDIG_NA_PREFIX="${SYSDIG_NA_APP_NAME}-[a-zA-Z0-9]" 
[[ -n "${SYSDIG_KSPM_COLLECTOR_APP_NAME//[[:space:]]/}" ]] && export SYSDIG_KSPMC_PREFIX="${SYSDIG_KSPM_COLLECTOR_APP_NAME}-[a-zA-Z0-9]"

  printf "Init vars completed\n"
  log_activity "initVar completed."

  log_activity "Prefix for hostShield/agent $SYSDIG_AGENT_PREFIX"
  log_activity "Prefix for clusterShield $SYSDIG_CS_PREFIX"
  log_activity "Prefix for nodeAnalyzer $SYSDIG_NA_PREFIX"
  log_activity "Prefix for kspmCollector $SYSDIG_KSPMC_PREFIX"
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
printf "Please put y if your environment has restrictions on internet access or no internet access, or if you just want to generate the archive. \n Put n if your env do not have any kind of restrictions for internet access, this will require the S3 bucket url provided by Sysdig support\n"
read answer
log_activity "Selected $answer as response for internet restrictions"
clear
}

function collectArtifacts()
{
  log_activity "Starting collectArtifacts (namespace: ${namespace}, pod: ${podName:-ALL})"
  if [ -z $podName ]; then
    printf "Getting all sysdig pods configuration, this could take a while\n"
    log_activity "Collecting cluster info (version output)."
    $k8sCmd version -o json > $DEST_DIR/$SYSDIG_SUPPORT_DIR/cluster_info.json
    log_activity "Collected cluster_info.json."

    $k8sCmd get po --sort-by='.status.containerStatuses[0].restartCount' --no-headers -n $namespace -o wide > $DEST_DIR/$SYSDIG_SUPPORT_DIR/running_pods.txt
    log_activity "Saved running_pods.txt."

    if [[ "$k8sCmd" == "oc" ]]; then
      $k8sCmd adm top pod -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/top_pods.txt
      log_activity "Collected pod resource usage (oc mode)."
    else
      $k8sCmd top pod -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/top_pods.txt || printf "Metrics server not installed or ready, moving forward\n"
      log_activity "Collected pod resource usage (kubectl mode)."
    fi

    $k8sCmd describe po -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/describe_pods.txt
    $k8sCmd get cm -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/configmap.txt
    $k8sCmd get ds -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/daemonset.txt
    $k8sCmd get deploy -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/deployment.txt
    log_activity "Saved configmap.txt, daemonset.txt, deployment.txt, describe_pods.txt"

    $k8sCmd describe nodes > $DEST_DIR/$SYSDIG_SUPPORT_DIR/nodes.txt
    log_activity "Saved nodes.txt."

    printf "Configuration collection completed for all Sysdig pods\n"
    log_activity "Configuration collection completed for all pods."
  else
    printf "Getting the pod configuration for the pod %s\n" "$podName"
    $k8sCmd get po --sort-by='.status.containerStatuses[0].restartCount' --no-headers -n $namespace -o wide > $DEST_DIR/$SYSDIG_SUPPORT_DIR/running_pods.txt
    log_activity "Saved running_pods.txt."
    log_activity "Collecting cluster info for specific pod $podName"
    $k8sCmd version -o json > $DEST_DIR/$SYSDIG_SUPPORT_DIR/cluster_info.json
    if [[ "$k8sCmd" == "oc" ]]; then
      $k8sCmd adm top pod -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/top_pods.txt
      log_activity "Collected pod resource usage (oc mode)."
    else
      $k8sCmd top pod -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/top_pods.txt || printf "Metrics server not installed or ready, moving forward\n"
      log_activity "Collected pod resource usage (kubectl mode)."
    fi
    $k8sCmd get po $podName -n $namespace -o wide > $DEST_DIR/$SYSDIG_SUPPORT_DIR/${podName}_node.txt
    log_activity "Saved ${podName}_node.txt."
    $k8sCmd describe po $podName -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/describe_pods_${podName}.txt
    log_activity "Saved describe_pods_${podName}.txt."
    $k8sCmd get cm -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/configmap.txt
    $k8sCmd get ds -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/daemonset.txt
    $k8sCmd get deploy -o yaml -n $namespace > $DEST_DIR/$SYSDIG_SUPPORT_DIR/deployment.txt
    log_activity "Saved configmap.txt, daemonset.txt, deployment.txt."
    $k8sCmd describe nodes > $DEST_DIR/$SYSDIG_SUPPORT_DIR/nodes.txt
    log_activity "Saved nodes.txt."
    printf "Configuration collection completed for pod %s \n" "$podName"
    log_activity "Configuration collection completed for pod $podName"
  fi

  printf "Collecting cluster object counts\n"
  deployments=$($k8sCmd get deployments --all-namespaces --no-headers 2>/dev/null | wc -l)
  replicasets=$($k8sCmd get replicasets --all-namespaces --no-headers 2>/dev/null | wc -l)
  namespaces=$($k8sCmd get namespaces --no-headers 2>/dev/null | wc -l)
  configmaps=$($k8sCmd get configmaps --all-namespaces --no-headers 2>/dev/null | wc -l)
  pods=$($k8sCmd get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
  {
    printf "Cluster Object Counts:\n"
    printf -- "-----------------------\n"
    printf "Deployments : $deployments\n"
    printf "ReplicaSets : $replicasets\n"
    printf "Namespaces : $namespaces\n"
    printf "ConfigMaps : $configmaps\n"
    printf "Pods : $pods"
  } > $DEST_DIR/$SYSDIG_SUPPORT_DIR/cluster_object_counts.txt
  log_activity "Saved cluster_object_counts.txt with deployments:$deployments, replicasets:$replicasets, namespaces:$namespaces, configmaps:$configmaps, pods:$pods."
  [ ! -z $SYSDIG_CS_APP_NAME ] && CS_POD_IP=`cat $DEST_DIR/$SYSDIG_SUPPORT_DIR/running_pods.txt|grep -E $SYSDIG_CS_PREFIX|head -1|awk '{print $6}'` || printf "ClusterShield is not running, or not available\n"
  log_activity "collectArtifacts completed."
}

function getLogs()
{
  log_activity "Starting getLogs (namespace: $namespace, pod: ${podName:-ALL})"
  local csAttempt=0
  local drAgentAttempt=0
  if [ -z $podName ]; then
    printf "Getting all sysdig logs, this could take a while\n"
    for pod in $(awk '{print $1}' < "$DEST_DIR/$SYSDIG_SUPPORT_DIR/running_pods.txt"); do
      printf "Getting log of pod %s \n" "$pod"
      log_activity "Attempting log collection for pod $pod"
      if [[ -n "$SYSDIG_AGENT_PREFIX" ]] && [[ $pod =~ $SYSDIG_AGENT_PREFIX ]]; then
        mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod
        $k8sCmd -n $namespace cp $pod:${AGENT_LOG_DIR}. $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod --retries=$AGENT_CP_RETRY 2>/dev/null
        if [[ $? -eq 0 ]] ; then
          log_activity "Copied agent log files for pod $pod."
        else
          log_activity "ERROR: Failed to copy logs for pod $pod (possibly recycled)."
        fi
        if [[ $CS_POD_IP != "" && $csAttempt -eq 0 ]]; then
          log_activity "Tryng to perform curl against cluster shield health endpoint. If no error are reported, the call has been performed successfully"
          $k8sCmd exec $pod -n $namespace -- curl "http://${CS_POD_IP}:${SYSDIG_CS_MONITORING_PORT}/${SYSDIG_CS_ENDPOINT}"> $DEST_DIR/$SYSDIG_SUPPORT_DIR/csFeaturesStatus.txt 2>/dev/null || log_activity "Unable to call CS health endpoint, moving forward"
          ((csAttempt++))
        fi
        if [[ $drAgentAttempt -eq 0 ]]; then
          log_activity "Getting dragent.yaml from pod $pod"
          $k8sCmd -n $namespace cp $pod:$AGENT_DRAGENT_DIR/dragent.yaml $DEST_DIR/$SYSDIG_SUPPORT_DIR/dragent.yaml 2>/dev/null
          log_activity "Getting dragent.yaml from pod $pod completed!"
          ((drAgentAttempt++))
        fi
        
      fi
      if [[ -n "$SYSDIG_CS_PREFIX" ]] && [[ $pod =~ $SYSDIG_CS_PREFIX  ]]; then
        mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$SYSDIG_CS_DIR
        $k8sCmd -n $namespace logs $pod > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$SYSDIG_CS_DIR/$pod.log 2>/dev/null
        if [[ $? -eq 0 ]]; then
          log_activity "Collected cluster shield log for pod $pod"
        else
          log_activity "ERROR: Failed to collect cluster shield log for pod $pod (pod not found)."
        fi
      fi
      if [[ -n "$SYSDIG_NA_PREFIX" ]] && [[ $pod =~ $SYSDIG_NA_PREFIX ]]; then
        mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_KSPMA_CONTAINER_NAME > /dev/null 2>&1 && \
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_KSPMA_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod/${pod}_${SYSDIG_KSPMA_CONTAINER_NAME}.log && \
        log_activity "Collected kspm-analyzer logs for pod $pod" || \
        log_activity "kspm-analyzer not installed for pod $pod"
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_HS_CONTAINER_NAME > /dev/null 2>&1 && \
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_HS_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod/${pod}_${SYSDIG_HS_CONTAINER_NAME}.log && \
        log_activity "Collected host-scanner logs for pod $pod" || \
        log_activity "host-scanner not installed for pod $pod"
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_RS_CONTAINER_NAME > /dev/null 2>&1 && \
        $k8sCmd -n $namespace logs $pod -c $SYSDIG_RS_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod/${pod}_${SYSDIG_RS_CONTAINER_NAME}.log && \
        log_activity "Collected runtime-scanner logs for pod $pod" || \
        log_activity "runtime-scanner not installed for pod $pod"
      fi
      if [[ -n "$SYSDIG_KSPMC_PREFIX" ]] && [[ $pod =~ $SYSDIG_KSPMC_PREFIX ]]; then
        mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod
        $k8sCmd -n $namespace logs $pod > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$pod/$pod.log 2>/dev/null
        if [ $? -eq 0 ]; then
          log_activity "Collected kspmcollector log for pod $pod"
        else
          log_activity "ERROR: Failed to collect kspmcollector log for pod $pod (pod not found)."
        fi
      fi
    done
    log_activity "Log collection completed for all pods."
  else
    log_activity "Attempting log collection for pod ${podName}."
    if [[ $podName =~ $SYSDIG_AGENT_PREFIX ]]; then
      printf "Collecting log for pod %s\n" "$podName"
      mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName
      $k8sCmd -n $namespace cp $podName:${AGENT_LOG_DIR}. $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName --retries=$AGENT_CP_RETRY 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod %s\n" "$podName"
        log_activity "Collected agent log for pod $podName "
      else
        log_activity "ERROR: Failed to collect agent log for pod $podName (possibly recycled)."
      fi
      $k8sCmd -n $namespace cp $podName:$AGENT_DRAGENT_DIR/dragent.yaml $DEST_DIR/$SYSDIG_SUPPORT_DIR/dragent.yaml 2>/dev/null
    fi
    if [[ $podName =~ $SYSDIG_CS_PREFIX ]]; then
      printf "Collecting log for pod %s\n" "$podName"
      mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$SYSDIG_CS_DIR
      $k8sCmd -n $namespace logs $podName > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$SYSDIG_CS_DIR/$podName.log 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod %s\n" "$podName"
        log_activity "Collected cluster shield log for pod ${podName}."
      else
        log_activity "ERROR: Failed to collect cluster shield log for pod ${podName} (pod not found)."
      fi
    fi
    if [[ $podName =~ $SYSDIG_NA_PREFIX ]]; then
      printf "Collecting log for pod %s\n" "$podName"
      mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_KSPMA_CONTAINER_NAME > /dev/null 2>&1 && \
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_KSPMA_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName/${podName}_$SYSDIG_KSPMA_CONTAINER_NAME.log && \
      log_activity "Collected kspm-analyzer log for pod $podName" || \
      log_activity "kspm-analyzer not installed for pod $podName"
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_HS_CONTAINER_NAME > /dev/null 2>&1 && \
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_HS_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName/${podName}_$SYSDIG_HS_CONTAINER_NAME.log && \
      log_activity "Collected host-scanner log for pod $podName" || \
      log_activity "host-scanner not installed for pod $podName"
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_RS_CONTAINER_NAME > /dev/null 2>&1 && \
      $k8sCmd -n $namespace logs $podName -c $SYSDIG_RS_CONTAINER_NAME > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName/${podName}_$SYSDIG_RS_CONTAINER_NAME.log && \
      log_activity "Collected runtime-scanner log for pod $podName" || \
      log_activity "runtime-scanner not installed for pod $podName"
      printf "Log collected for pod %s\n" "$podName"
    fi
    if [[ $podName =~ $SYSDIG_KSPMC_PREFIX ]]; then
      printf "Collecting log for pod %s\n" "$podName"
      mkdir -p $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName
      $k8sCmd -n $namespace logs $podName > $DEST_DIR/$SYSDIG_SUPPORT_DIR/logs/$podName/$podName.log 2>/dev/null
      if [ $? -eq 0 ]; then
        printf "Log collected for pod %s\n" "$podName"
        log_activity "Collected kspmcollector log for pod $podName"
      else
        log_activity "ERROR: Failed to collect kspmcollector log for pod $podName"
      fi
    fi
    log_activity "Log collection completed for pod $podName"
  fi
  log_activity "getLogs completed."
}

function compressAndUpload()
{
  cd $DEST_DIR/$SYSDIG_SUPPORT_DIR
  printf "Creating archive file %s\n" "$ARCHIVE_NAME"
  log_activity "Starting archive creation: $ARCHIVE_NAME"
  errorMessage=$(tar czf $ARCHIVE_NAME * 2>&1)
  if [ $? -eq 0 ]; then
    printf "Archive file created successfully, ready for upload!\n"
    log_activity "Archive $ARCHIVE_NAME created successfully."
  else
    printf "Something went wrong\n"
    printf "%s\n" "$errorMessage"
    log_activity "Failed to create archive $ARCHIVE_NAME : $errorMessage"
    exit $ERR_RC_TAR
  fi
if [ $answer == "y" ];
  then
  printf "The archive has been saved in the path $DEST_DIR/$SYSDIG_SUPPORT_DIR , archive name is $ARCHIVE_NAME\n"
  IS_AIRGAPPED="true"
  cleanArtifacts $IS_AIRGAPPED
  printf "Script execution completed, exit \n"
  exit 0
 else

  printf "Please put the S3 link provided by Sysdig Support, the script will upload the archive on the case.\n"
  read SYSDIG_UPLOAD_URL
  log_activity "User provided S3 upload URL: $SYSDIG_UPLOAD_URL"

  printf "The status of the upload will not be shown, please be patient\n"
  log_activity "Uploading $ARCHIVE_NAME to S3 $SYSDIG_UPLOAD_URL"
  httpRetCode=$(curl -s -S -o /dev/null -w "%{http_code}" -X PUT --url "${SYSDIG_UPLOAD_URL}" -H "Content-Disposition: attachment; filename=${ARCHIVE_NAME}" -T "${ARCHIVE_NAME}")
  if [ $httpRetCode -eq 200 ]; then
    printf "Archive file uploaded successfully!\n"
    log_activity "Archive uploaded successfully to S3."
    cleanArtifacts
  else
    printf "Something went wrong\n"
    log_activity "S3 upload failed with curl exit code $httpRetCode"
    printf "The archive has been saved in the path $DEST_DIR/$SYSDIG_SUPPORT_DIR"
    exit $ERR_RC_CURL
  fi

  printf "Script execution completed!\n"
  log_activity "Script execution completed."
fi
}

function cleanArtifacts
{

printf "Cleanup started\n"
log_activity "Script Cleanup Started"

cd $DEST_DIR/$SYSDIG_SUPPORT_DIR

printf "Removing cluster_info.json file\n"
rm -f cluster_info.json
printf "Removing dragent.yaml file\n"
rm -f dragent.yaml 
printf "Removing txt file\n"
rm -f *.txt
  
if [ $IS_AIRGAPPED == "false" ];
  then
  printf "Removing archive file $ARCHIVE_NAME \n"
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