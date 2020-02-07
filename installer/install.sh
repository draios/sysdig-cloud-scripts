#!/usr/bin/env bash

set -euo pipefail

# globals
MINIMUM_CPUS=16
MINIMUM_MEMORY_KB=31000000
MINIMUM_DISK_IN_GB=59

function logError() { echo "$@" 1>&2; }

#log to file and stdout
log_file="/var/log/sysdig-installer.log"
exec &>> >(tee -a "$log_file")

if [[ "$EUID" -ne 0 ]]; then
  logError "This script needs to be run as root"
  logError "Usage: sudo ./$0"
  exit 1
fi

MINIKUBE_VERSION=v1.6.2
KUBERNETES_VERSION=v1.16.0
DOCKER_VERSION=18.06.3
ROOT_LOCAL_PATH="/usr/bin"
QUAYPULLSECRET="PLACEHOLDER"
LICENSE="PLACEHOLDER"
DNSNAME="PLACEHOLDER"
AIRGAP_BUILD="false"
AIRGAP_INSTALL="false"
INSTALLER_IMAGE="quay.io/sysdig/installer:3.0.0-5"

function writeValuesYaml() {
  cat << EOM > values.yaml
size: small
quaypullsecret: $QUAYPULLSECRET
apps: monitor secure agent
storageClassProvisioner: hostPath
elasticsearch:
  hostPathNodes:
    - minikube
sysdig:
  mysql:
    hostPathNodes:
      - minikube
  postgresql:
    hostPathNodes:
      - minikube
  cassandra:
    hostPathNodes:
      - minikube
  dnsName: $DNSNAME
  admin:
    username: pov@sysdig.com
  license: $LICENSE
  resources:
    api:
      requests:
        cpu: 500m
        memory: 1Gi
    cassandra:
      requests:
        cpu: 500m
        memory: 1Gi
    collector:
      requests:
        cpu: 500m
        memory: 1Gi
    elasticsearch:
      requests:
        cpu: 500m
        memory: 1Gi
    worker:
      requests:
        cpu: 500m
        memory: 1Gi
EOM
}

function checkCPU() {
  local -r cpus=$(grep -c processor /proc/cpuinfo)

  if [[ $cpus -lt $MINIMUM_CPUS ]]; then
    logError "The number of cpus '$cpus' is less than the required number of cpus: '$MINIMUM_CPUS'"
    exit 1
  fi

  echo "Enough cpu ✓"
}

function checkMemory() {
  local -r memory=$(grep MemTotal /proc/meminfo | awk '{print $2}')

  if [[ $memory -lt $MINIMUM_MEMORY_KB ]]; then
    logError "The amount of memory '$memory' is less than the required amount of memory in kilobytes '$MINIMUM_MEMORY_KB'"
    exit 1
  fi

  echo "Enough memory ✓"
}

function checkDisk() {
  local -r diskSizeHumanReadable=$(df -h /var | tail -n1 | awk '{print $2}')
  local -r diskSize=${diskSizeHumanReadable%G}

  if [[ $diskSize -lt $MINIMUM_DISK_IN_GB ]]; then
    logError "The volume that holds the var directory needs a minimum of '$MINIMUM_DISK_IN_GB' but currently has '$diskSize'"
    exit 1
  fi

  echo "Enough disk ✓"
}

function preFlight() {
  echo "Running preFlight checks"
  checkCPU
  checkMemory
  checkDisk
}

function askQuestions() {
  if [[ "${AIRGAP_BUILD}" != "true" ]]; then
    read -rp $'Provide quay pull secret: \n' QUAYPULLSECRET
    printf "\n"
    read -rp $'Provide sysdig license: \n' LICENSE
    printf "\n"
    read -rp $'Provide domain name, this domain name should resolve to this node on port 443 and 6443: \n' DNSNAME
    printf "\n"
  else
    local -r quayPullSecret="${QUAYPULLSECRET}"
    if [[ "$quayPullSecret" == "PLACEHOLDER" ]]; then
      logError "-q|--quaypullsecret is needed for airgap build"
      exit 1
    fi
  fi
}

function dockerLogin() {
  local -r quayPullSecret=$QUAYPULLSECRET
  if [[ "$quayPullSecret" != "PLACEHOLDER" ]]; then
    local -r auth=$(echo "$quayPullSecret" | base64 --decode | jq -r '.auths."quay.io".auth' | base64 --decode)
    local -r quay_username=${auth%:*}
    local -r quay_password=${auth#*:}
    docker login -u "$quay_username" -p "$quay_password" quay.io
  else
    logError "Please rerun the script and configure quay pull secret"
    exit 1
  fi
}

function installUbuntuDeps() {
  apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1
  apt-get update -qq
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"
  apt-get update -qq
  apt-get install -y --allow-unauthenticated docker-ce=${DOCKER_VERSION}~ce~3-0~ubuntu
}

function installDebianDeps() {
  apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1
  apt-get update -qq
  apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  apt-get update -qq
  apt-get install -y --allow-unauthenticated docker-ce=${DOCKER_VERSION}~ce~3-0~debian
}

function installCentOSDeps() {
  local -r version=$1
  yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
  yum -y update
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  if [[ $version == 8 ]]; then
    yum install -y yum-utils device-mapper-persistent-data lvm2 curl
  else
    yum install -y yum-utils device-mapper-persistent-data lvm2 curl
  fi
  # Copied from https://github.com/kubernetes/kops/blob/b92babeda277df27b05236d852b5c0dc0803ce5d/nodeup/pkg/model/docker.go#L758-L764
  yum install -y http://vault.centos.org/7.6.1810/extras/x86_64/Packages/container-selinux-2.68-1.el7.noarch.rpm
  yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.06.3.ce-3.el7.x86_64.rpm
  systemctl enable docker
  systemctl start docker
}

function disableFirewalld() {
  echo "Disabling firewald...."
  systemctl stop firewalld
  systemctl disable firewalld
}

function installMiniKube() {
  curl -s -Lo minikube "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"
  chmod +x minikube
  mv minikube "${ROOT_LOCAL_PATH}"
}

function installKubectl() {
  curl -s -Lo kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl "${ROOT_LOCAL_PATH}"
}

function installJq() {
  curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x jq
  mv jq "${ROOT_LOCAL_PATH}"
}

function installDeps() {
  set +e

  cat << EOF > /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
EOF
  modprobe br_netfilter
  sysctl --system

  source /etc/os-release
  case $ID in
    ubuntu)
      installUbuntuDeps
      if [[ ! $VERSION_CODENAME =~ ^(bionic|xenial)$ ]]; then
        logError "ubuntu version: $VERSION_CODENAME is not supported"
        exit 1
      fi
      ;;
    debian)
      installDebianDeps
      if [[ ! $VERSION_CODENAME =~ ^(stretch|buster)$ ]]; then
        logError "debian version: $VERSION_CODENAME is not supported"
        exit 1
      fi
      ;;
    centos | amzn)
      if [[ $ID =~ ^(centos)$ ]] &&
        [[ ! "$VERSION_ID" =~ ^(7|8) ]]; then
        logError "$ID version: $VERSION_ID is not supported"
        exit 1
      fi
      disableFirewalld
      installCentOSDeps "$VERSION_ID"
      ;;
    *)
      logError "unsupported platform $ID"
      exit 1
      ;;
  esac
  installJq
  installMiniKube
  installKubectl
  set -e
}

function startDocker() {
  systemctl enable docker
  systemctl start docker
  ip link set docker0 promisc on
}

function startMinikube() {
  export MINIKUBE_HOME="/root"
  export KUBECONFIG="/root/.kube/config"
  minikube start --vm-driver=none --kubernetes-version=${KUBERNETES_VERSION}
  systemctl enable kubelet
  kubectl config use-context minikube
  minikube update-context
}

function fixIptables() {
  echo "Fixing iptables ..."
  ### Install iptables rules because minikube locks out external access
  iptables -I INPUT -t filter -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -t filter -p tcp --dport 6443 -j ACCEPT
  iptables -I INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
}

function pullImagesSysdigImages(){
  #copy tests/resources to local
  getSysdigImagesFromInstaller
  #find images in resources
  mapfile -t non_job_images < <(jq -r '.spec.template.spec.containers[]? | .image' \
    resources/*/sysdig.json 2> /dev/null | sort -u | grep 'quay\|docker.io')
  mapfile -t job_images < <(jq -r '.spec.jobTemplate.spec.template.spec.containers[]? | .image' \
    resources/*/sysdig.json 2> /dev/null | sort -u | grep 'quay\|docker.io')
  #collected images  to images obj
  local -a images=("${non_job_images[@]}")
  images+=("${job_images[@]}")
  #iterate and pull image if not present
  for image in "${images[@]}"; do
    if [[ -z $(docker images -q "$image") ]]; then
      logger info "Pulling $image"
      docker pull "$image"
    else
      echo "$image is present"
    fi
  done
  #clean up resources
  rm -rf resources
}

function getSysdigImagesFromInstaller(){
  #get resources from sysdig-chart/tests
  docker create --name installer_image ${INSTALLER_IMAGE}
  docker cp installer_image:/sysdig-chart/tests/resources .
  docker rm  installer_image
}

function runInstaller() {
  if [[ "${AIRGAP_INSTALL}" != "true" ]]; then
    dockerLogin
  fi
  if [[ "${AIRGAP_BUILD}" == "true" ]]; then
    docker pull "${INSTALLER_IMAGE}"
    pullImagesSysdigImages
  else
    writeValuesYaml
    docker run --net=host \
      -e KUBECONFIG=/root/.kube/config \
      -v /root/.kube:/root/.kube:Z \
      -v /root/.minikube:/root/.minikube:Z \
      -v "$(pwd)":/manifests:Z \
      "${INSTALLER_IMAGE}"
  fi
}

function __main() {
  preFlight
  askQuestions
  if [[ "${AIRGAP_INSTALL}" != "true" ]]; then
    installDeps
    startDocker
  fi
  #minikube needs to run to set the correct context & ip during airgap run
  startMinikube
  if [[ "${AIRGAP_INSTALL}" != "true" ]]; then
    fixIptables
  fi
  runInstaller
}

while [[ $# -gt 0 ]]
do
arguments="$1"

case "${arguments}" in
    -a|--airgap-build)
    AIRGAP_BUILD="true"
    LICENSE="installer.airgap.license"
    DNSNAME="installer.airgap.dnsname"
    shift # past argument
    ;;
    -i|--airgap-install)
    AIRGAP_INSTALL="true"
    LICENSE="installer.airgap.license"
    DNSNAME="installer.airgap.dnsname"
    shift # past argument
    ;;
    -q|--quaypullsecret)
    QUAYPULLSECRET="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Help..."
    echo "use -a|--airgap-builder to specify airgap builder"
    echo "-q|--quaypullsecret followed by quaysecret to specify airgap builder"
    shift # past argument
    exit 0
    ;;
    *)    # unknown option
    shift # past argument
    logError "unknown arg $1"
    exit 1
    ;;
esac
done

__main
