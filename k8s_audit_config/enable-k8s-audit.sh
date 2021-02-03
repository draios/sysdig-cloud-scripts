#!/usr/bin/env bash

set -euxo pipefail

VARIANT=${1:-NONE}

function fatal() {
	MESSAGE=$1

	echo "${MESSAGE}"
	echo "Exiting."
	exit 1
}

function copy_using_cmd() {
    COPY_CMD_TMPL=$1
    SOURCEFILE=$2
    DESTFILE=$3

    CMD=$(echo "${COPY_CMD_TMPL}" | SOURCEFILE=$SOURCEFILE DESTFILE=$DESTFILE envsubst)

    bash -c "${CMD}"
}

function prepare_webhook_config() {
    echo "***Creating suitable webhook configuration file from sysdig agent service cluster ip..."
    AGENT_SERVICE_CLUSTERIP="${AGENT_SERVICE_CLUSTERIP}" envsubst <webhook-config.yaml.in >webhook-config.yaml
}

function prepare_audit_sink_config() {
    echo "***Creating suitable audit sink configurations files from sysdig agent service cluster ip..."
    AGENT_SERVICE_CLUSTERIP="${AGENT_SERVICE_CLUSTERIP}" envsubst <audit-sink.yaml.in >audit-sink.yaml
}

echo "Checking for required commands..."
command -v yq || fatal "Could not find program \"yq\""
command -v jq || fatal "Could not find program \"jq\""

APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " " | cut -f2 -d: | cut -f3 -d/)
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath="{.spec.clusterIP}" -n sysdig-agent)

if [[ "$VARIANT" == minikube* ]]; then
    SSH_CMD="ssh -i $(minikube ssh-key) docker@$(minikube ip)"
    COPY_CMD="scp -i $(minikube ssh-key) \$SOURCEFILE docker@$(minikube ip):\$DESTFILE"
elif [ "$VARIANT" == "minishift-3.11" ]; then
    SSH_CMD="minishift ssh"
    COPY_CMD="(minishift ssh \"cat > \$DESTFILE\") < \$SOURCEFILE"
elif [ "$VARIANT" == "openshift-3.11" ]; then
    SSH_CMD="ssh centos@$APISERVER"
    COPY_CMD="scp \$SOURCEFILE centos@$APISERVER:\$DESTFILE"
elif [[ "$VARIANT" == "openshift-4.2" ]]; then
    echo "***Updating kube-apiserver configuration..."
    CUR_REVISION=$(oc get pod -l app=openshift-kube-apiserver -n openshift-kube-apiserver -o jsonpath={.items[0].metadata.labels.revision})
    EXP_REVISION=$((CUR_REVISION+1))
    oc patch kubeapiserver cluster --type=merge -p '{"spec":{"unsupportedConfigOverrides":{"apiServerArguments":{"audit-dynamic-configuration":["true"],"feature-gates":["DynamicAuditing=true"],"runtime-config":["auditregistration.k8s.io/v1alpha1=true"]}}}}'
    echo "Waiting for apiserver pod to restart..."
    POD_STATUS="N/A"
    ATTEMPT=0
    while [ "${POD_STATUS}" != "Running" ]; do
        if [ "$ATTEMPT" == 20 ]; then
            fatal "kube-apiserver pod not restarted after 10 minutes, not continuing."
        fi
        sleep 30
        ATTEMPT=$((ATTEMPT+1))
        echo "Checking pod status (Attempt ${ATTEMPT})..."
        POD_STATUS=$(oc get pod -l revision=${EXP_REVISION},app=openshift-kube-apiserver -n openshift-kube-apiserver -o jsonpath={.items[0].status.phase} 2>&1 || true)
    done
    echo "Creating dynamic audit sink..."
    prepare_audit_sink_config
    kubectl apply -f audit-sink.yaml
elif [[ "$VARIANT" == "gke" ]]; then
    echo "Enter your gce project id: "
    read GCE_PROJECT_ID
    echo "Will use GCE Project Id: $GCE_PROJECT_ID"
    echo "Creating GCE Service Account that has the ability to read logs..."
    RET=$(gcloud iam service-accounts list --filter="name=projects/$GCE_PROJECT_ID/serviceAccounts/swb-logs-reader@$GCE_PROJECT_ID.iam.gserviceaccount.com" 2>&1)

    if [[ "$RET" != "Listed 0 items." ]]; then
        echo "Service account exists ($RET), not creating again"
    else
        gcloud iam service-accounts create swb-logs-reader --description "Service account used by stackdriver-webhook-bridge" --display-name "stackdriver-webhook-bridge logs reader"
        gcloud projects add-iam-policy-binding "$GCE_PROJECT_ID" --member serviceAccount:swb-logs-reader@"$GCE_PROJECT_ID".iam.gserviceaccount.com --role 'roles/logging.viewer'
        gcloud iam service-accounts keys create "$PWD"/swb-logs-reader-key.json --iam-account swb-logs-reader@"$GCE_PROJECT_ID".iam.gserviceaccount.com
    fi

    echo "Creating k8s secret containing service account keys..."
    kubectl delete secret stackdriver-webhook-bridge -n sysdig-agent|| true
    kubectl create secret generic stackdriver-webhook-bridge --from-file=key.json="$PWD"/swb-logs-reader-key.json -n sysdig-agent

    echo "Deploying stackdriver-webhook-bridge to sysdig-agent namespace..."
    curl -LO https://raw.githubusercontent.com/sysdiglabs/stackdriver-webhook-bridge/master/stackdriver-webhook-bridge.yaml
    kubectl apply -f stackdriver-webhook-bridge.yaml -n sysdig-agent

    echo "Done."

    exit 0

elif [[ "$VARIANT" == "iks" ]]; then
    echo "Enter your IKS Cluster name/id: "
    read IKS_CLUSTER_NAME
    echo "Will use IKS cluster name: $IKS_CLUSTER_NAME"
    echo "Setting the cluster webhook backend url to the IP address of the sysdig-agent service..."
    ibmcloud ks cluster master audit-webhook set --cluster "$IKS_CLUSTER_NAME" --remote-server http://$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent):7765/k8s_audit
    echo "IKS webhook now set to:"
    ibmcloud ks cluster master audit-webhook get --cluster "$IKS_CLUSTER_NAME"
    echo "Refreshing the cluster master. It might take several minutes for the master to refresh..."
    ibmcloud ks cluster master refresh --cluster "$IKS_CLUSTER_NAME"

    echo "Done."

    exit 0

elif [[ "$VARIANT" == "rke-1.13" ]]; then
    echo "Path to RKE cluster.yml file: "
    read RKE_CLUSTER_YAML
    RKE_CLUSTER_YAML="${RKE_CLUSTER_YAML/#\~/$HOME}"
    echo "Will modify ${RKE_CLUSTER_YAML} to add audit policy/webhook configuration. Saving current version to ${RKE_CLUSTER_YAML}.old"
    cp "${RKE_CLUSTER_YAML}" "${RKE_CLUSTER_YAML}.old"

    APISERVER=$(yq r -j ${RKE_CLUSTER_YAML} | jq -r '.nodes | map(select(.role[] | contains ("controlplane")))| .[] .address')
    SSH_USER=$(yq r -j ${RKE_CLUSTER_YAML} | jq -r '.nodes | map(select(.role[] | contains ("controlplane")))| .[] .user')

    SSH_CMD="ssh -t $SSH_USER@$APISERVER"
    COPY_CMD="scp \$SOURCEFILE $SSH_USER@$APISERVER:\$DESTFILE"
elif [[ "$VARIANT" == "kops" ]]; then

    prepare_webhook_config
    prepare_audit_sink_config

    if [ -z ${KOPS_CLUSTER_NAME+x} ]; then
        echo "Enter your kops cluster name: "
        read KOPS_CLUSTER_NAME
    fi

    echo "Fetching current kops cluster configuration..."
    kops get cluster $KOPS_CLUSTER_NAME -o yaml > cluster-current.yaml

    echo "Adding webhook configuration/audit policy to cluster configuration..."

    cat <<EOF > merge.yaml
spec:
    fileAssets:
      - name: webhook-config
        path: /var/lib/k8s_audit/webhook-config.yaml
        roles: [Master]
        content: |
$(cat webhook-config.yaml | sed -e 's/^/          /')
      - name: audit-policy
        path: /var/lib/k8s_audit/audit-policy.yaml
        roles: [Master]
        content: |
$(cat audit-policy.yaml | sed -e 's/^/          /')
    kubeAPIServer:
        auditLogPath: /var/lib/k8s_audit/audit.log
        auditLogMaxBackups: 1
        auditLogMaxSize: 10
        auditWebhookBatchMaxWait: 5s
        auditPolicyFile: /var/lib/k8s_audit/audit-policy.yaml
        auditWebhookConfigFile: /var/lib/k8s_audit/webhook-config.yaml
EOF

    yq m -a=append cluster-current.yaml merge.yaml > cluster.yaml

    echo "Configuring kops with the new cluster configuration..."
    kops replace -f cluster.yaml

    echo "Updating the cluster configuration to prepare changes to the cluster."
    kops update cluster --yes

    echo "Performing a rolling update to redeploy the master nodes with the new files and apiserver configuration. . It make take several minutes for the rolling-update to complete..."
    kops rolling-update cluster --yes

    echo "Done."
    exit 0
else
    echo "Unknown K8s Distribution+version $VARIANT. Exiting."
    exit 1
fi

# If here, we need to manually copy files to the apiserver node and patch the config. 
prepare_webhook_config
prepare_audit_sink_config

echo "***Copying apiserver config patch script/supporting files to apiserver..."
$SSH_CMD "rm -rf /tmp/enable_k8s_audit && mkdir -p /tmp/enable_k8s_audit"

for f in apiserver-config.patch.sh audit-policy.yaml webhook-config.yaml; do
    echo "   $f"
    copy_using_cmd "${COPY_CMD}" $f /tmp/enable_k8s_audit/$f
done

echo "***Modifying k8s apiserver config.."

$SSH_CMD "sudo bash /tmp/enable_k8s_audit/apiserver-config.patch.sh $VARIANT"

if [ "$VARIANT" == "minishift-3.11" ]; then

    # The documented instructions to enable audit logs for 3.11 don't work for minishift,
    # as changes to master-config.yaml are not properly converted to command line arguments
    # by "hypershift openshift-kube-apiserver". So instead, we modify the api server command
    #  line arguments directly.

DEL_PATCH=$(cat <<EOF
{"kubernetesMasterConfig":
    {"apiServerArguments":
        {"audit-log-path": null,
         "audit-log-maxbackup": null,
         "audit-log-maxsize": null,
         "audit-policy-file": null,
         "audit-webhook-config-file": null,
         "audit-webhook-batch-max-wait": null,
         "audit-webhook-mode": null
        }
    }
}
EOF
)

PATCH=$(cat <<EOF
{"kubernetesMasterConfig":
    {"apiServerArguments":
        {"audit-log-path": ["/etc/origin/master/k8s_audit_events.log"],
         "audit-log-maxbackup": ["1"],
         "audit-log-maxsize": ["10"],
         "audit-policy-file": ["/etc/origin/master/audit-policy.yaml"],
         "audit-webhook-config-file": ["/etc/origin/master/webhook-config.yaml"],
         "audit-webhook-batch-max-wait": ["5s"],
         "audit-webhook-mode": ["batch"]
        }
    }
}
EOF
)
    # The first patch deletes any existing values for those command line
    # args. The second adds the new command line args.
    minishift openshift config set --target kube --patch "$DEL_PATCH"
    minishift openshift config set --target kube --patch "$PATCH"

    echo "**Restarting API Server.."
    minishift openshift restart
elif [ "$VARIANT" == "openshift-3.11" ]; then
    echo "**Restarting API Server.."
    $SSH_CMD sudo /usr/local/bin/master-restart api
    $SSH_CMD sudo /usr/local/bin/master-restart controllers
elif [[ "${VARIANT}" == "minikube-1.13" ]]; then
    echo "Waiting for api server to restart..."
    RC=1
    while [ $RC -ne "0" ]; do
        sleep 5
        kubectl get nodes
        RC=$?
    done
    echo "Creating dynamic audit sink..."
    kubectl apply -f audit-sink.yaml
elif [[ "${VARIANT}" == "rke-1.13" ]]; then
    echo "Modifying ${RKE_CLUSTER_YAML} to add audit policy/webhook configuration..."
    yq w "${RKE_CLUSTER_YAML}" services.kube-api.extra_args.audit-policy-file /var/lib/k8s_audit/audit-policy.yaml \
        | yq w - services.kube-api.extra_args.audit-webhook-config-file /var/lib/k8s_audit/webhook-config.yaml \
        | yq w - services.kube-api.extra_args.audit-webhook-batch-max-wait 5s \
        | yq w - services.kube-api.extra_binds[+] "/var/lib/k8s_audit:/var/lib/k8s_audit" \
        > "${RKE_CLUSTER_YAML}.new"
    mv "${RKE_CLUSTER_YAML}.new" "${RKE_CLUSTER_YAML}"
    rke up --config "${RKE_CLUSTER_YAML}"
fi

echo "***Done!"
