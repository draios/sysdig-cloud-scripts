#!/bin/bash

# Installer for Sysdig Agent on IBM Cloud Kubernetes Service (IKS)

set -e

function install_curl_deb {
    export DEBIAN_FRONTEND=noninteractive

    if ! hash curl > /dev/null 2>&1; then
        echo "* Installing curl"

        if [[ -z $CMD_PREF ]]; then
            unprivileged
        fi

        $CMD_PREF apt-get update
        $CMD_PREF apt-get -qq -y install curl < /dev/null
    fi
}

function install_curl_rpm {
    if ! hash curl > /dev/null 2>&1; then
        echo "* Installing curl"

        if [[ -z $CMD_PREF ]]; then
            unprivileged
        fi

        $CMD_PREF yum -q -y install curl
    fi
}

function download_yamls {
    echo "* Downloading yamls files to the temp directory: $WORKDIR"
    echo "* Downloading Sysdig cluster role yaml"
    curl -s -o $WORKDIR/sysdig-agent-clusterrole.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-clusterrole.yaml
    echo "* Downloading Sysdig config map yaml"
    curl -s -o $WORKDIR/sysdig-agent-configmap.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-configmap.yaml
    echo "* Downloading Sysdig daemonset v2 yaml"
    curl -s -o $WORKDIR/sysdig-agent-daemonset-v2.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-daemonset-v2.yaml
    echo "* Downloading Sysdig daemonset slim v2 yaml"
    curl -s -o $WORKDIR/sysdig-agent-slim-daemonset-v2.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-slim-daemonset-v2.yaml
    echo "* Downloading Sysdig kmod-thin-agent-slim daemonset"
    curl -s -o $WORKDIR/sysdig-kmod-thin-agent-slim-daemonset.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-kmod-thin-agent-slim-daemonset.yaml
    if [ $INSTALL_IMAGE_ANALYZER -eq 1 ]; then
        echo "* Downloading Sysdig Image Analyzer config map yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-image-analyzer-configmap.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-configmap.yaml
        echo "* Downloading Sysdig Image Analyzer daemonset v1 yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-image-analyzer-daemonset.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-daemonset.yaml
    elif [ $INSTALL_NODE_ANALYZER -eq 1 ]; then
        echo "* Downloading Sysdig Image Analyzer config map yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-image-analyzer-configmap.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-configmap.yaml
        echo "* Downloading Sysdig Benchmark Runner config map yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-benchmark-runner-configmap.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-benchmark-runner-configmap.yaml
        echo "* Downloading Sysdig Host Analyzer config map yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-host-analyzer-configmap.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-host-analyzer-configmap.yaml
        echo "* Downloading Sysdig Node Analyzer daemonset v1 yaml"
        curl -H 'Cache-Control: no-cache' -s -o $WORKDIR/sysdig-node-analyzer-daemonset.yaml https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-node-analyzer-daemonset.yaml
    fi
}

function unsupported {
    echo "Unsupported operating system. Try using the manual installation instructions"
    exit 1
}

function unprivileged {
    echo "Unable to perform action as the current user. Please run this script as the root user"
    exit 1
}

function help {
    echo "Usage: $(basename ${0}) -a | --access_key <value> [-t | --tags <value>] [-c | --collector <value>] \ "
    echo "                [-cp | --collector_port <value>] [-s | --secure <value>] [-cc | --check_certificate <value>] \ "
    echo "                [-ns | --namespace | --project <value>] [-ac | --additional_conf <value>] [-np | --no-prometheus] \ "
    echo "                [-sn | --sysdig_instance_name <value>] [-op | --openshift] [-af | --agent-full] [-as | --agent-slim] \ "
    echo "                [-ae | --api_endpoint <value> ] [-na | --nodeanalyzer ] \ "
    echo "                [-ia | --imageanalyzer ] [-am | --analysismanager <value>] [-ds | --dockersocket <value>] [-cs | --crisocket <value>] [-cv | --customvolume <value>] \ "
    echo "                [-av | --agent-version <value>] [ -r | --remove ] [ -aws | --aws ] [-h | --help]"
    echo ""
    echo " -a  : secret access key, as shown in Sysdig Monitor"
    echo " -t  : list of tags for this host (ie. \"role:webserver,location:europe\", \"role:webserver\" or \"webserver\")"
    echo " -c  : collector IP for Sysdig Monitor"
    echo " -cp : collector port [default 6443]"
    echo " -s  : use a secure SSL/TLS connection to send metrics to the collector (default: true)"
    echo " -cc : enable strong SSL certificate check (default: true)"
    echo " -ac : if provided, the additional configuration will be appended to agent configuration file"
    echo " -ns : if provided, will be the namespace used to deploy the agent. Defaults to ibm-observe"
    echo " -np : if provided, do not enable the Prometheus collector.  Defaults to enabling Prometheus collector"
    echo " -sn : if provided, name of the sysdig instance (optional)"
    echo " -op : if provided, perform the installation using the OpenShift command line"

    echo " -as : if provided, use agent-slim (this is the default agent). Note: this option is not required"
    echo " -af : if provided, use agent-full instead of agent-slim"
    echo " -ac : if provided, the additional configuration will be appended to agent configuration file"
    echo " -av : if provided, use the agent-version specified. (default: latest)"
    echo " -r  : if provided, will remove the sysdig agent's daemonset, configmap, clusterrolebinding,"
    echo "       serviceacccount and secret from the specified namespace"
    echo " -ae : if provided, will be used as the base (host) for the Node Analyzer endpoints."
    echo " -na : if provided, will install the Node Analyzer. It is an error to set both -ia and -na."
    echo " -ia : if provided, will install the Node Image Analyzer. It is an error to set both -ia and -na."
    echo " -aws : if provided, will support AWS cluster name parsing and not use ICR"
    echo " -am : Analysis Manager endpoint for Sysdig Secure"
    echo " -ds : docker socket for Image Analyzer"
    echo " -cs : CRI socket for Image Analyzer"
    echo " -cd : CRI-containerd socket for Image Analyzer"
    echo " -cv : custom volume for Image Analyzer"
    echo " -h  : print this usage and exit"
    echo
    exit 1
}

function is_valid_value {
    if [[ ${1} == -* ]] || [[ ${1} == --* ]] || [[ -z ${1} ]]; then
        return 1
    else
        return 0
    fi
}

function create_namespace {
    fail=0
    if [ $OPENSHIFT -eq 0 ]; then
        echo "* Creating namespace: $NAMESPACE"
        out=$(kubectl create namespace $NAMESPACE 2>&1) || { fail=1 && echo "kubectl create namespace failed!"; }
    else
        echo "* Creating project: $NAMESPACE"
        out=$(oc adm new-project $NAMESPACE --node-selector='app=sysdig-agent' 2>&1) || { fail=1 && echo "oc adm new-project failed!"; }
        # label all nodes
        oc label node --all "app=sysdig-agent"

        # Set the project to the namespace
        switch=$(oc project $NAMESPACE 2>&1)
    fi
    if [ $fail -eq 1 ]; then
        if [[ "$out" =~ "AlreadyExists" || "$out" =~ "already exists" ]]; then
            echo "$out. Continuing..."
        else
            echo "$out"
            exit 1
        fi
    fi
}


function create_sysdig_serviceaccount {
    fail=0
    if [ $OPENSHIFT -eq 0 ]; then
        echo "* Creating sysdig-agent serviceaccount in namespace: $NAMESPACE"
        out=$(kubectl create serviceaccount sysdig-agent --namespace=$NAMESPACE 2>&1) || { fail=1 && echo "kubectl create serviceaccount failed!"; }
    else
        echo "* Creating sysdig-agent serviceaccount in project: $NAMESPACE"
        out=$(oc create serviceaccount sysdig-agent -n $NAMESPACE 2>&1) || { fail=1 && echo "oc create serviceaccount failed!"; }
    fi
    if [ $fail -eq 1 ]; then
        if [[ "$out" =~ "AlreadyExists" || "$out" =~ "already exists" ]]; then
            echo "$out. Continuing..."
        else
            echo "$out"
            exit 1
        fi
    fi
}

function install_k8s_agent {
    fail=0
    if [ $OPENSHIFT -eq 0 ]; then
        echo "* Creating sysdig-agent clusterrole and binding"
        kubectl apply -f $WORKDIR/sysdig-agent-clusterrole.yaml
        outbinding=$(kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=$NAMESPACE:sysdig-agent --namespace=$NAMESPACE 2>&1) || \
          { fail=1 && echo "kubectl create clusterrolebinding failed!"; }
    else
        echo "* Creating sysdig-agent access policies"
        outbinding=$(oc adm policy add-scc-to-user privileged -n $NAMESPACE -z sysdig-agent 2>&1) || { fail=1 && echo "oc adm policy add-scc-to-user failed!"; }
        if [ $fail -eq 0 ]; then
            outbinding=$(oc adm policy add-cluster-role-to-user cluster-reader -n $NAMESPACE -z sysdig-agent 2>&1) || { fail=1 && echo "oc adm policy add-cluster-role-to-user failed!"; }
        fi
    fi
    if [ $fail -eq 1 ]; then
        if [[ "$outbinding" =~ "AlreadyExists" || "$outbinding" =~ "already exists" ]]; then
            echo "$outbinding. Continuing..."
        else
            echo "$outbinding"
            exit 1
        fi
    fi

    echo "* Creating sysdig-agent secret using the ACCESS_KEY provided"
    fail=0
    outsecret=$(kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESS_KEY --namespace=$NAMESPACE 2>&1) || { fail=1 && echo "kubectl create secret failed!"; }
    if [ $fail -eq 1 ]; then
        if [[ "$outsecret" =~ "AlreadyExists" || "$outsecret" =~ "already exists" ]]; then
            echo "$outsecret. Re-creating secret..."
            kubectl delete secrets sysdig-agent --namespace=$NAMESPACE 2>&1
            kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESS_KEY --namespace=$NAMESPACE 2>&1
        else
            echo "$outsecret"
            exit 1
        fi
    fi

    CONFIG_FILE=$WORKDIR/sysdig-agent-configmap.yaml

    echo "* Retrieving the Cluster ID and Cluster Name"
    IKS_CLUSTER_ID=$(kubectl get cm -n kube-system cluster-info -o yaml | grep ' "cluster_id": ' | cut -d'"' -f4)
    if [ $OPENSHIFT -eq 0 ]; then
        CLUSTER_NAME=$(kubectl config current-context)
        # Parse  out AWS cluster name
        if [ $AWS -eq 1 ]; then
            CLUSTER_NAME=$(echo $CLUSTER_NAME | cut -d'/' -f2)
        fi
    else
        # Pull the cluster name using the cluster ID using ibmcloud ks
        # since the current-context is not a user-friendly value
        fail=0
        CLUSTER_NAME=$(ibmcloud ks cluster get --cluster "$IKS_CLUSTER_ID" --json | jq -r .name) || { fail=1 && echo "Failed to get the cluster name"; }
        if [ $fail -eq 1 ]; then
            echo "Failed to get the cluster name from the Cluster ID using ibmcloud ks - $CLUSTER_ID "
            echo "Attempting to retrieve the current-context for the cluster name"
            # Get a default cluster name
            CLUSTER_NAME=$(kubectl config current-context)
        fi
    fi

    if [ ! -z "$CLUSTER_NAME" ]; then
        echo "* Setting cluster name as $CLUSTER_NAME"
        echo -e "    k8s_cluster_name: $CLUSTER_NAME" >> $CONFIG_FILE
    fi

    if [ ! -z "$IKS_CLUSTER_ID" ]; then
        echo "* Setting ibm.containers-kubernetes.cluster.id $IKS_CLUSTER_ID"
        if [ -z "$TAGS" ]; then
            TAGS="ibm.containers-kubernetes.cluster.id:$IKS_CLUSTER_ID"
        else
            TAGS="$TAGS,ibm.containers-kubernetes.cluster.id:$IKS_CLUSTER_ID"
        fi
    fi

    echo "* Updating agent configmap and applying to cluster"
    if [ ! -z "$TAGS" ]; then
        echo "* Setting tags"
        echo "    tags: $TAGS" >> $CONFIG_FILE
    fi

    if [ ! -z "$COLLECTOR" ]; then
        echo "* Setting collector endpoint"
        echo "    collector: $COLLECTOR" >> $CONFIG_FILE
    fi

    if [ ! -z "$COLLECTOR_PORT" ]; then
        echo "* Setting collector port"
        echo "    collector_port: $COLLECTOR_PORT" >> $CONFIG_FILE
    else
        echo "    collector_port: 6443" >> $CONFIG_FILE
    fi

    if [ ! -z "$SECURE" ]; then
        echo "* Setting connection security"
        echo "    ssl: $SECURE" >> $CONFIG_FILE
    else
        echo "    ssl: true" >> $CONFIG_FILE
    fi

    if [ ! -z "$CHECK_CERT" ]; then
        echo "* Setting SSL certificate check level"
        echo "    ssl_verify_certificate: $CHECK_CERT" >> $CONFIG_FILE
    else
        echo "    ssl_verify_certificate: true" >> $CONFIG_FILE
    fi

    # Disable agent captures
    echo -e "    sysdig_capture_enabled: false" >> $CONFIG_FILE

    if [ ! -z "$ADDITIONAL_CONF" ]; then
        echo "* Adding additional configuration to dragent.yaml"
        echo -e "    $ADDITIONAL_CONF" >> $CONFIG_FILE
    fi

    if [ $ENABLE_PROMETHEUS -eq 1 ]; then
        echo "* Enabling Prometheus"
        echo -e "    prometheus:" >> $CONFIG_FILE
        echo -e "        enabled: true" >> $CONFIG_FILE
    fi

    echo -e "    new_k8s: true" >> $CONFIG_FILE
    kubectl apply -f $CONFIG_FILE --namespace=$NAMESPACE

    if [ $INSTALL_IMAGE_ANALYZER -eq 1 ] || [ $INSTALL_NODE_ANALYZER -eq 1 ]; then
        # Image Analyzer config map
        IA_CONFIG_FILE=$WORKDIR/sysdig-image-analyzer-configmap.yaml

        # If the collector was changed but the analysis manager was not this was
        # most likely an onprem install, add the default analysis manager for that onprem
        if [ ! -z "$API_ENDPOINT" ] && [ -z "$ANALYSIS_MANAGER" ]; then
            ANALYSIS_MANAGER="https://${API_ENDPOINT}/internal/scanning/scanning-analysis-collector"
            echo "* Configuring Analysis Manager endpoint to ${ANALYSIS_MANAGER}. You can also use the -am option to explicitly specify it."
        elif [ ! -z "$COLLECTOR" ] && [ -z "$ANALYSIS_MANAGER" ]; then
            ANALYSIS_MANAGER="https://${COLLECTOR}/internal/scanning/scanning-analysis-collector"
            echo "* Configuring Analysis Manager endpoint to ${ANALYSIS_MANAGER}. You can also use the -am option to explicitly specify it."
        fi

        if [ ! -z "$ANALYSIS_MANAGER" ]; then
          echo "* Setting Analysis Manager endpoint for Image Analyzer"
          echo "  collector_endpoint: $ANALYSIS_MANAGER" >> $IA_CONFIG_FILE
        fi
        if [ ! -z "$DOCKER_SOCKET_PATH" ]; then
          echo "* Setting docker socket path"
          echo "  docker_socket_path: $DOCKER_SOCKET_PATH" >> $IA_CONFIG_FILE
        fi
        if [ ! -z "$CRI_SOCKET_PATH" ]; then
          echo "* Setting CRI socket path"
          echo "  cri_socket_path: $CRI_SOCKET_PATH" >> $IA_CONFIG_FILE
        fi
        if [ ! -z "$CRI_CONTAINERD_SOCKET_PATH" ]; then
          echo "* Setting CRI-containerd socket path"
          echo "  containerd_socket_path: $CRI_CONTAINERD_SOCKET_PATH" >> $IA_CONFIG_FILE
        fi
        if [ ! -z "$CHECK_CERT" ]; then
          echo "* Setting SSL certificate check level"
          echo "  ssl_verify_certificate: \"$CHECK_CERT\"" >> $IA_CONFIG_FILE
        else
          echo "  ssl_verify_certificate: \"true\"" >> $IA_CONFIG_FILE
        fi

        kubectl apply -f $IA_CONFIG_FILE --namespace=$NAMESPACE
    fi

    if [ $INSTALL_NODE_ANALYZER -eq 1 ]; then
        # Benchmark Runner config map
        BR_CONFIG_FILE=$WORKDIR/sysdig-benchmark-runner-configmap.yaml

        if [ ! -z "$API_ENDPOINT" ]; then
            echo "* Setting API endpoint for Benchmark Runner"
            echo "  collector_endpoint: https://$API_ENDPOINT" >> $BR_CONFIG_FILE
        elif [ ! -z "$COLLECTOR" ]; then
            echo "* Setting Collector endpoint for Benchmark Runner"
            echo "  collector_endpoint: https://$COLLECTOR" >> $BR_CONFIG_FILE
        fi

        if [ ! -z "$CHECK_CERT" ]; then
            echo "* Setting SSL certificate check level"
            echo "  ssl_verify_certificate: \"$CHECK_CERT\"" >> $BR_CONFIG_FILE
        else
            echo "  ssl_verify_certificate: \"true\"" >> $BR_CONFIG_FILE
        fi

        kubectl apply -f $BR_CONFIG_FILE --namespace=$NAMESPACE

        # Host Analyzer config map
        HA_CONFIG_FILE=$WORKDIR/sysdig-host-analyzer-configmap.yaml

        echo "* Using Analysis Manager endpoint for Host Analyzer: ${ANALYSIS_MANAGER}"
        echo "  collector_endpoint: $ANALYSIS_MANAGER" >> $HA_CONFIG_FILE

        if [ ! -z "$CHECK_CERT" ]; then
            echo "* Setting SSL certificate check level"
            echo "  ssl_verify_certificate: \"$CHECK_CERT\"" >> $HA_CONFIG_FILE
        else
            echo "  ssl_verify_certificate: \"true\"" >> $HA_CONFIG_FILE
        fi

        kubectl apply -f $HA_CONFIG_FILE --namespace=$NAMESPACE
    fi

    if [ $AGENT_FULL -eq 1 ]; then
        echo "Full agent selected "
        DAEMONSET_FILE="$WORKDIR/sysdig-agent-daemonset-v2.yaml"
        AGENT_STRING="agent"
        AGENT_NAMES="agent"
    else
        echo "Slim agent selected "
        DAEMONSET_FILE="$WORKDIR/sysdig-kmod-thin-agent-slim-daemonset.yaml"
        AGENT_STRING="agent-slim"
        AGENT_NAMES="agent-slim agent-kmodule"
    fi

    # -i.bak argument used for compatibility between mac (-i '') and linux (simply -i)
    sed -i.bak -e "s|# serviceAccount: sysdig-agent|serviceAccount: sysdig-agent|" $DAEMONSET_FILE

    # For IBM use IBM Cloud Container Registry
    if [ $AWS -eq 0 ]; then
        for agent_name in ${AGENT_NAMES}; do
            # Use IBM Cloud Container Registry instead of docker.io or quay.io
            sed -i.bak -e "s|\( *image: \).*sysdig/${agent_name}\(.*\)|\1icr.io/ext/sysdig/${agent_name}:${AGENT_VERSION}|g" $DAEMONSET_FILE
        done

        ICR_SECRET_EXIST=$(kubectl -n default get secret -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -qE "default-icr-io|all-icr-io" || echo 1)
        if [ "$ICR_SECRET_EXIST" = 1 ]; then
            # Throw an error instead of running the command for them because it could
            #  take a long time for the secrets to become populated
            echo "ERROR: default-icr-io or all-icr-io secret doesn't exist in the default namespace"
            echo "ERROR: Run the following:"
            if [ "$OPENSHIFT" = 1 ]; then
                echo "ibmcloud iam service-id-create all-icr-io --description \"Grant access to private Sysdig agent image\""
                echo "ibmcloud iam service-api-key-create all-icr-io-apikey all-icr-io"
                echo "oc -n default create secret docker-registry all-icr-io --docker-username=iamapikey --docker-password=all-icr-io-apikey"
            else
                echo "ibmcloud ks cluster pull-secret apply --cluster $IKS_CLUSTER_ID"
            fi
            exit 1
        fi

        # Add the icr secret to our namespace. Delete beforehand to avoid conflicts
        kubectl -n $NAMESPACE delete secret $NAMESPACE-icr-io 2>/dev/null || true
        kubectl -n $NAMESPACE delete secret all-icr-io 2>/dev/null || true

        # Use the pull secret in the daemonset flie. macOS's sed doesn't like \n
        INDENT=$(grep 'containers' $DAEMONSET_FILE | sed 's/\( *\).*/\1/')
        echo "${INDENT}imagePullSecrets:" >> $DAEMONSET_FILE

        kubectl -n default get secrets -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -E "default-icr-io|all-icr-io" | while read default_secret; do
            SECRET_NAME=$(echo ${default_secret} | sed "s/default-/$NAMESPACE-/g")

            echo "Processing ${default_secret} as ${SECRET_NAME}"
            kubectl get secret ${default_secret} -n default -o json | \
              jq "del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid) | .metadata.creationTimestamp=null | .metadata.name|=\"${SECRET_NAME}\"" | \
              kubectl apply -n ${NAMESPACE} -f -

            echo "${INDENT}- name: $SECRET_NAME" >> $DAEMONSET_FILE
        done
    else
        for agent_name in ${AGENT_NAMES}; do
            # Don't use IBM Cloud Container Registry when not running in IBM. Force quay.io and append the version
            sed -i.bak -e "s|\( *image: \).*sysdig/${agent_name}\(.*\)|\1quay.io/sysdig/${agent_name}:${AGENT_VERSION}|g" $DAEMONSET_FILE
        done
    fi

    # Add label for Sysdig instance
    if [ ! -z "$SYSDIG_INSTANCE_NAME" ]; then
       sed -i.bak -e 's/^\( *\)labels:$/&\
\1  sysdig-instance: '$SYSDIG_INSTANCE_NAME'/' $DAEMONSET_FILE
    fi

    echo "* Deploying the sysdig agent"
    kubectl apply -f $DAEMONSET_FILE --namespace=$NAMESPACE
    sleep 5 # So we gave some time to create the pods and show something meaningful in the next command

    echo -e "\nThe list of agent pods deployed in the namespace \"$NAMESPACE\" are:"
    kubectl get pods -n $NAMESPACE | { grep "sysdig-agent" || true; }

    echo -e "\nMake sure the above pods all turn to \"Running\" state before continuing"
    echo "Should any pod not reach the \"Running\" state, further info can be obtained from logs as follows"
    echo "'kubectl logs <agent-pod-name> -n $NAMESPACE' "

    if [ $INSTALL_IMAGE_ANALYZER -eq 1 ]; then
      # Deploy Image Analyzer
      IA_FILE=$WORKDIR/sysdig-image-analyzer-daemonset.yaml
      if [ ! -z "$IA_CUSTOM_PATH" ]; then
        NL="\n"
        if [[ $uname -eq "Darwin" ]]; then
          NL=$'\\\n'
        fi

        IA_MATCH="Add custom volume here"
        IA_INSERT_VOLUME="      - name: custom-volume${NL}        hostPath:${NL}          path: ${IA_CUSTOM_PATH}"

        sed -i.bak -e "s|${IA_MATCH}|${IA_MATCH}${NL}${IA_INSERT_VOLUME}|" $IA_FILE

        IA_MATCH="Add custom volume mount here"
        IA_INSERT_VOLUME="        - mountPath: ${IA_CUSTOM_PATH}${NL}          name: custom-volume"

        sed -i.bak -e "s|${IA_MATCH}|${IA_MATCH}${NL}${IA_INSERT_VOLUME}|" $IA_FILE
      fi

      echo "* Deploying the Image Analyzer"
      kubectl apply -f $IA_FILE --namespace=$NAMESPACE
      sleep 5 # So we gave some time to create the pods and show something meaningful in the next command

      echo -e "\nThe list of Image Analyzers pods deployed in the namespace \"$NAMESPACE\" are:"
      kubectl get pods -n $NAMESPACE | { grep "image-analyzer" || true; }
    elif [ $INSTALL_NODE_ANALYZER -eq 1 ]; then
        # Deploy Node Analyzer
        NA_FILE=$WORKDIR/sysdig-node-analyzer-daemonset.yaml
        if [ ! -z "$NA_CUSTOM_PATH" ]; then
            NL="\n"
            if [[ $uname -eq "Darwin" ]]; then
                NL=$'\\\n'
            fi

            IA_MATCH="Add custom volume here"
            IA_INSERT_VOLUME="      - name: custom-volume${NL}        hostPath:${NL}          path: ${IA_CUSTOM_PATH}"

            sed -i.bak -e "s|${IA_MATCH}|${IA_MATCH}${NL}${IA_INSERT_VOLUME}|" $NA_FILE

            IA_MATCH="Add custom volume mount here"
            IA_INSERT_VOLUME="        - mountPath: ${IA_CUSTOM_PATH}${NL}          name: custom-volume"

            sed -i.bak -e "s|${IA_MATCH}|${IA_MATCH}${NL}${IA_INSERT_VOLUME}|" $NA_FILE
        fi

        echo "* Deploying the Node Analyzer"
        kubectl apply -f $NA_FILE --namespace=$NAMESPACE
        sleep 5 # So we gave some time to create the pods and show something meaningful in the next command

        echo -e "\nThe list of Node Analyzer pods deployed in the namespace \"$NAMESPACE\" are:"
        kubectl get pods -n $NAMESPACE | { grep "node-analyzer" || true; }
    fi
}

function remove_agent {
    set +e

    echo "* Deleting the Sysdig agent and configurings from namespace $NAMESPACE"

    echo "* Deleting the sysdig-agent daemonset"
    kubectl delete daemonset sysdig-agent --namespace=$NAMESPACE

    echo "* Deleting the sysdig-agent configmap"
    kubectl delete configmap sysdig-agent --namespace=$NAMESPACE

    echo "* Deleting the sysdig-agent serviceacccount"
    kubectl delete serviceaccount -n default sysdig-agent --namespace=$NAMESPACE

    if [ "$(kubectl get pods -n $NAMESPACE | grep -c image-analyzer)" -ge 1 ]; then
      echo "* Deleting the sysdig-image-analyzer daemonset"
      kubectl delete daemonset sysdig-image-analyzer --namespace=$NAMESPACE

      echo "* Deleting the sysdig-image-analyzer configmap"
      kubectl delete configmap sysdig-image-analyzer --namespace=$NAMESPACE
    elif [ "$(kubectl get pods -n $NAMESPACE | grep -c node-analyzer)" -ge 1 ]; then
        echo "* Deleting the sysdig-node-analyzer daemonset"
        kubectl delete daemonset sysdig-node-analyzer --namespace=$NAMESPACE

        echo "* Deleting the sysdig-image-analyzer configmap"
        kubectl delete configmap sysdig-image-analyzer --namespace=$NAMESPACE

        echo "* Deleting the sysdig-benchmark-runner configmap"
        kubectl delete configmap sysdig-benchmark-runner --namespace=$NAMESPACE
    fi

    if [ $OPENSHIFT -eq 0 ]; then
        echo "* deleting the sysdig-agent clusterrolebinding"
        kubectl delete clusterrolebinding sysdig-agent

        echo "* Deleting the sysdig-agent clusterrole"
        kubectl delete clusterrole sysdig-agent
    else
        echo "* Removing cluster role and security constraints"
        oc adm policy remove-cluster-role-from-user cluster-reader -n $NAMESPACE -z sysdig-agent
        oc adm policy remove-scc-from-user privileged -n $NAMESPACE -z sysdig-agent

        echo "* Deleting labels from oc nodes"
        oc label node --all app-
    fi

    echo "* Deleting the sysdig-agent secret"
    kubectl delete secret sysdig-agent --namespace=$NAMESPACE

    echo "* Note, the namespace '$NAMESPACE' is not deleted. It could have other resources"

    set -e
}

cleanup_workdir() {
    rm -rf "$WORKDIR"
}

if [[ ${#} -eq 0 ]]; then
    echo "ERROR: Sysdig Access Key & Collector are mandatory, use -h | --help for $(basename ${0}) Usage"
    exit 1
fi

# Setting the default value for NAMESPACE to be ibm-observe
# Will be over-ridden if the -ns|--namespace flag is provided
NAMESPACE="ibm-observe"
REMOVE_AGENT=0
ENABLE_PROMETHEUS=1
OPENSHIFT=0
INSTALL_IMAGE_ANALYZER=0
INSTALL_NODE_ANALYZER=0
AGENT_VERSION="latest"
AWS=0
AGENT_FULL=0
WORKDIR="$(mktemp -d /tmp/sysdig-agent-k8s.XXXXXX)"
trap cleanup_workdir EXIT ERR

while [[ ${#} > 0 ]]
do
key="${1}"

case ${key} in
    -a|--access_key)
        if is_valid_value "${2}"; then
            ACCESS_KEY="${2}"
        else
            echo "ERROR: no value provided for access_key option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -t|--tags)
        if is_valid_value "${2}"; then
            TAGS="${2}"
        else
            echo "ERROR: no value provided for tags option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -c|--collector)
        if is_valid_value "${2}"; then
            COLLECTOR="${2}"
        else
            echo "ERROR: no value provided for collector endpoint option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -cp|--collector_port)
        if is_valid_value "${2}"; then
            COLLECTOR_PORT="${2}"
        else
            echo "ERROR: no value provided for collector port option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -s|--secure)
        if is_valid_value "${2}"; then
            SECURE="${2}"
        else
            echo "ERROR: no value provided for connection security option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -cc|--check_certificate)
        if is_valid_value "${2}"; then
            CHECK_CERT="${2}"
        else
            echo "ERROR: no value provided for SSL check certificate option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -ns|--namespace|--project)
        if is_valid_value "${2}"; then
            NAMESPACE="${2}"
        else
            echo "ERROR: no value provided for namespace, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -ac|--additional_conf)
        if is_valid_value "${2}"; then
            ADDITIONAL_CONF="${2}"
        else
            echo "ERROR: no value provided for additional conf option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -np|--no-prometheus)
        ENABLE_PROMETHEUS=0
        ;;
    -sn|--sysdig_instance_name)
        if is_valid_value "${2}"; then
            SYSDIG_INSTANCE_NAME="${2}"
        else
            echo "ERROR: no value provided for sysdig instance name use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -av|--agent-version)
    if is_valid_value "${2}"; then
            AGENT_VERSION="${2}"
        else
            echo "ERROR: no value provided for agent version use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -op|--openshift)
        OPENSHIFT=1
        ;;
    -af|--agent-full)
        AGENT_FULL=1
        ;;
    -as|--agent-slim)
        AGENT_FULL=0
        echo "Using --agent-slim option (this is the default option). Note: this option is not required"
        ;;
    -aws|--aws)
        AWS=1
        ;;
    -r|--remove)
        REMOVE_AGENT=1
        ;;
    -am|--analysismanager)
        if is_valid_value "${2}"; then
            ANALYSIS_MANAGER="${2}"
        else
            echo "ERROR: no value provided for Analysis Manager option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -ds|--dockersocket)
        if is_valid_value "${2}"; then
            DOCKER_SOCKET_PATH="${2}"
        else
            echo "ERROR: no value provided for docker socket path option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -cs|--crisocket)
        if is_valid_value "${2}"; then
            CRI_SOCKET_PATH="${2}"
        else
            echo "ERROR: no value provided for CRI socket path option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -cd|--cricontainerdsocket)
        if is_valid_value "${2}"; then
            CRI_CONTAINERD_SOCKET_PATH="${2}"
        else
            echo "ERROR: no value provided for CRI-containerd socket path option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -cv|--customvolume)
        if is_valid_value "${2}"; then
            IA_CUSTOM_PATH="${2}"
        else
            echo "ERROR: no value provided for custom volume path option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -ae|--api_endpoint)
        if is_valid_value "${2}"; then
            API_ENDPOINT="${2}"
        else
            echo "ERROR: no value provided for API endpoint option, use -h | --help for $(basename ${0}) Usage"
            exit 1
        fi
        shift
        ;;
    -ia|--imageanalyzer)
        INSTALL_IMAGE_ANALYZER=1
        ;;
    -na|--nodeanalyzer)
        INSTALL_NODE_ANALYZER=1
        ;;
    -h|--help)
        help
        exit 1
        ;;
    *)
        echo "ERROR: Invalid option: ${1}, use -h | --help for $(basename ${0}) Usage"
        exit 1
        ;;
esac
shift
done

CMD_PREF=""
if [ $(id -u) != 0 ]; then
    if command -v sudo  > /dev/null 2>&1; then
        CMD_PREF="sudo "
    fi
fi

if [ $REMOVE_AGENT -eq 1 ]; then
    remove_agent
    exit 0
fi

if [ -z $ACCESS_KEY  ]; then
    echo "ERROR: Sysdig Access Key argument is mandatory, use -h | --help for $(basename ${0}) Usage"
    exit 1
fi

if [ -z $COLLECTOR ]; then
    echo "ERROR: Sysdig Collector argument is mandatory, use -h | --help for $(basename ${0}) Usage"
    exit 1
fi

if [ $INSTALL_IMAGE_ANALYZER -eq 1 ] && [ $INSTALL_NODE_ANALYZER -eq 1 ]; then
    echo "ERROR: The Node Analyzer and Node Image Analyzer cannot both be installed. use -h | --help for $(basename ${0}) Usage"
    exit 1
fi


echo "* Detecting operating system"
ARCH=$(uname -m)
PLATFORM=$(uname)
if [[ ! $ARCH = *86 ]] && [ ! $ARCH = "x86_64" ] && [ ! $ARCH = "s390x" ]; then
    unsupported
fi

if [ -f /etc/debian_version ]; then
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        VERSION=${DISTRIB_RELEASE%%.*}
    else
        DISTRO="Debian"
        VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
    fi

    case "$DISTRO" in

        "Ubuntu")
            if [ $VERSION -ge 10 ]; then
                install_curl_deb
            else
                unsupported
            fi
            ;;

        "LinuxMint")
            if [ $VERSION -ge 9 ]; then
                install_curl_deb
            else
                unsupported
            fi
            ;;

        "Debian")
            if [ $VERSION -ge 6 ]; then
                install_curl_deb
            elif [[ $VERSION == *sid* ]]; then
                install_curl_deb
            else
                unsupported
            fi
            ;;

        *)
            unsupported
            ;;

    esac

elif [ -f /etc/system-release-cpe ]; then
    DISTRO=$(cat /etc/system-release-cpe | cut -d':' -f3)

    VERSION=$(cat /etc/system-release-cpe | cut -d':' -f5 | cut -d'.' -f1 | sed 's/[^0-9]*//g')

    case "$DISTRO" in

        "oracle" | "centos" | "redhat")
            if [ $VERSION -ge 6 ]; then
                install_curl_rpm
            else
                unsupported
            fi
            ;;

        "fedoraproject")
            if [ $VERSION -ge 13 ]; then
                install_curl_rpm
            else
                unsupported
            fi
            ;;

        *)
            unsupported
            ;;
    esac

elif [[ $uname -eq "Darwin" ]]; then
    install_curl_deb
else
    unsupported
fi

download_yamls
create_namespace
create_sysdig_serviceaccount
install_k8s_agent
