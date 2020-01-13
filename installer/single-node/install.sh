#!/usr/bin/env bash

set -euo pipefail

#log to file and stdout
log_file="/var/log/sysdig-installer.log"
exec &>> >(tee -a "$log_file")

if [[ "$EUID" -ne 0 ]]; then
  echo "This script needs to be run as root"
  echo "Usage: sudo ./$0"
  exit 1
fi

KUBERNETES_VERSION=v1.16.0
DOCKER_VERSION=18.06.3
ROOT_LOCAL_PATH="/usr/bin"
QUAYPULLSECRET="PLACEHOLDER"
LICENSE="PLACEHOLDER"
DNSNAME="PLACEHOLDER"

function writeValuesYaml() {
  cat << EOM > values.yaml
size: small
quaypullsecret: $QUAYPULLSECRET
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

function askQuestions() {
  read -rp $'Provide quay pull secret: \n' QUAYPULLSECRET
  printf "\n"
  read -rp $'Provide sysdig license: \n' LICENSE
  printf "\n"
  read -rp $'Provide domain name, this domain name should resolve to this node on port 443 and 6443: \n' DNSNAME
  printf "\n"
}

function dockerLogin() {
  local -r quayPullSecret=$QUAYPULLSECRET
  if [[ "$quayPullSecret" != "PLACEHOLDER" ]]; then
    local -r auth=$(echo "$quayPullSecret" | base64 --decode | jq -r '.auths."quay.io".auth' | base64 --decode)
    local -r quay_username=${auth%:*}
    local -r quay_password=${auth#*:}
    docker login -u "$quay_username" -p "$quay_password" quay.io
  else
    echo "Please rerun the script and configure quay pull secret"
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
  local -r minikube_latest=$(
    curl -sL \
      https://api.github.com/repos/kubernetes/minikube/releases/latest |
      jq -r .tag_name
  )
  curl -s -Lo minikube "https://storage.googleapis.com/minikube/releases/${minikube_latest}/minikube-linux-amd64"
  chmod +x minikube
  mv minikube "${ROOT_LOCAL_PATH}"
}

function installKubectl() {
  local -r kubectl_latest=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
  curl -s -Lo kubectl "https://storage.googleapis.com/kubernetes-release/release/${kubectl_latest}/bin/linux/amd64/kubectl"
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
        echo "ubuntu version: $VERSION_CODENAME is not supported"
        exit 1
      fi
      ;;
    debian)
      installDebianDeps
      if [[ ! $VERSION_CODENAME =~ ^(stretch|buster)$ ]]; then
        echo "debian version: $VERSION_CODENAME is not supported"
        exit 1
      fi
      ;;
    centos | amzn)
      if [[ $ID =~ ^(centos)$ ]] &&
        [[ ! "$VERSION_ID" =~ ^(7|8) ]]; then
        echo "$ID version: $VERSION_ID is not supported"
        exit 1
      fi
      disableFirewalld
      installCentOSDeps "$VERSION_ID"
      ;;
    *)
      echo "unsupported platform $ID"
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
}

function fixIptables() {
  echo "Fixing iptables ..."
  ### Install iptables rules because minikube locks out external access
  iptables -I INPUT -t filter -p tcp --dport 443 -j ACCEPT
  iptables -I INPUT -t filter -p tcp --dport 6443 -j ACCEPT
  iptables -I INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
}

function runInstaller() {
  dockerLogin
  docker run --net=host \
    -e KUBECONFIG=/root/.kube/config \
    -v /root/.kube:/root/.kube:Z \
    -v /root/.minikube:/root/.minikube:Z \
    -v "$(pwd)":/manifests:Z \
    quay.io/sysdig/installer:3.0.0-1
}

function __main() {
  askQuestions
  installDeps
  writeValuesYaml
  startDocker
  startMinikube
  fixIptables
  runInstaller
}

__main
