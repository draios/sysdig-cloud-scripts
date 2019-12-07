#!/usr/bin/env bash

set -euo pipefail

IFS=''
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

VARIANT=${1:-None}

function fatal() {
	MESSAGE=$1

	echo "${MESSAGE}"
	echo "Exiting."
	exit 1
}

function modify_openshift_master_yaml() {
	MASTER_CONFIG=$1
	ORIGFILE="${SCRIPTDIR}/master-config.yaml.original"

	cp "${MASTER_CONFIG}" "${ORIGFILE}"

	PATCH=$(
		cat <<EOF
auditConfig:
  enabled: true
  maximumFileSizeMegabytes: 10
  maximumRetainedFiles: 1
  auditFilePath: "/etc/origin/master/k8s_audit_events.log"
  logFormat: json
  webHookMode: "batch"
  webHookKubeConfig: /etc/origin/master/webhook-config.yaml
  policyFile: /etc/origin/master/audit-policy.yaml
EOF
	)
	# The first patch deletes any existing values for those command line
	# args. The second adds the new command line args.
	oc ex config patch "${ORIGFILE}" -p "$PATCH" >"${MASTER_CONFIG}"
}

echo "Updating API Server config files for variant ${VARIANT}:"

if [ "${VARIANT}" == "openshift-3.11" ]; then
	MASTER_CONFIG=/etc/origin/master/master-config.yaml

	if [ ! -f ${MASTER_CONFIG} ]; then
		fatal "Could not locate openshift apiserver configuration file"
	fi

	if grep "logFormat: json" ${MASTER_CONFIG}; then
		fatal "Existing audit config found. Remove that audit config before continuing."
	fi

	echo "Found openshift configuration file at ${MASTER_CONFIG}, modifying..."
	mkdir -p /etc/origin/master/
	cp "${SCRIPTDIR}/webhook-config.yaml" /etc/origin/master/webhook-config.yaml
	cp "${SCRIPTDIR}/audit-policy.yaml" /etc/origin/master/audit-policy.yaml
	modify_openshift_master_yaml ${MASTER_CONFIG}

elif [ "${VARIANT}" == "minishift-3.11" ]; then
	# Only need to copy the webhook/audit policy files. The config patching occurs in
	# enable-k8s-audit.sh using "minishift openshift config set"
	echo "Copying webhook config/audit policy files to /var/lib/minishift/base/kube-apiserver/..."
	cp "${SCRIPTDIR}/webhook-config.yaml" /var/lib/minishift/base/kube-apiserver/webhook-config.yaml
	cp "${SCRIPTDIR}/audit-policy.yaml" /var/lib/minishift/base/kube-apiserver/audit-policy.yaml

elif [[ "${VARIANT}" == minikube* ]]; then

	sudo mkdir -p /var/lib/k8s_audit
	if [[ "${VARIANT}" == *1.12* ]]; then
		cp "${SCRIPTDIR}/webhook-config.yaml" /var/lib/k8s_audit/webhook-config.yaml
	fi
	cp "${SCRIPTDIR}/audit-policy.yaml" /var/lib/k8s_audit/audit-policy.yaml

	APISERVER_PREFIX="    -"
	APISERVER_LINE="- kube-apiserver"
	MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

	if grep audit-policy-file "$MANIFEST"; then
		fatal "apiserver config patch already applied."
	fi

	TMPFILE="$SCRIPTDIR/kube-apiserver.yaml.patched"
	rm -f "$TMPFILE"

	while read -r LINE; do
		echo "$LINE" >>"$TMPFILE"
		case "$LINE" in
		*$APISERVER_LINE*)
			echo "$APISERVER_PREFIX --audit-log-path=/var/lib/k8s_audit/k8s_audit_events.log" >>"$TMPFILE"
			echo "$APISERVER_PREFIX --audit-policy-file=/var/lib/k8s_audit/audit-policy.yaml" >>"$TMPFILE"
			echo "$APISERVER_PREFIX --audit-log-maxbackup=1" >>"$TMPFILE"
			echo "$APISERVER_PREFIX --audit-log-maxsize=10" >>"$TMPFILE"
			if [[ "${VARIANT}" == *1.13* ]]; then
				echo "$APISERVER_PREFIX --audit-dynamic-configuration" >> "$TMPFILE"
				echo "$APISERVER_PREFIX --feature-gates=DynamicAuditing=true" >> "$TMPFILE"
				echo "$APISERVER_PREFIX --runtime-config=auditregistration.k8s.io/v1alpha1=true" >> "$TMPFILE"
			else
				echo "$APISERVER_PREFIX --audit-webhook-config-file=/var/lib/k8s_audit/webhook-config.yaml" >>"$TMPFILE"
				echo "$APISERVER_PREFIX --audit-webhook-batch-max-wait=5s" >>"$TMPFILE"
			fi
			;;
		*"volumeMounts:"*)
			echo "    - mountPath: /var/lib/k8s_audit/" >>"$TMPFILE"
			echo "      name: data" >>"$TMPFILE"
			;;
		*"volumes:"*)
			echo "  - hostPath:" >>"$TMPFILE"
			echo "      path: /var/lib/k8s_audit" >>"$TMPFILE"
			echo "    name: data" >>"$TMPFILE"
			;;

		esac
	done <"$MANIFEST"

	cp "$MANIFEST" "$SCRIPTDIR/kube-apiserver.yaml.original"
	cp "$TMPFILE" "$MANIFEST"
elif [[ "${VARIANT}" == "rke-1.13" ]]; then
	echo "Copying audit-policy.yaml to /var/lib/k8s_audit/audit-policy.yaml"
	sudo mkdir -p /var/lib/k8s_audit
	cp "$SCRIPTDIR"/audit-policy.yaml /var/lib/k8s_audit/audit-policy.yaml
	cp "$SCRIPTDIR"/webhook-config.yaml /var/lib/k8s_audit/webhook-config.yaml
else
	fatal "Unknown variant $VARIANT"
fi
