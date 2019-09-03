#!/usr/bin/env bash
set -uo pipefail

ENV="../../env.sh"

ENABLE=false
DISABLE=false
HELP=false

function print_usage() {
  echo "Usage: ./api_user_creation.sh [OPTION]"
  echo
  echo "Enables or disables API user creation for your Sysdig software platform installation"
  echo
  echo "If no OPTION is specified, current setting is printed"
  echo
  echo "Options:"
  echo "  -e             Enable API user creation"
  echo "  -d             Disable API user creation"
  echo "  -h             Print this Usage output"
  exit 1
}

eval "set -- $(getopt dhe "$@")"
while [[ $# -gt 0 ]] ; do
    case "${1}" in
      (-e) ENABLE=true ;;
      (-d) DISABLE=true ;;
      (-h) HELP=true ;;
      (--) shift; break;;
      (-*) echo "${0}: error - unrecognized option ${1}" 1>&2; exit 1;;
      (*)  break;;
    esac
    shift
done

if [[ $HELP = true ]] ; then
  print_usage
fi

if [[ $# -gt 0 ]] ; then
  echo "Excess command-line arguments detected. Exiting."
  echo
  print_usage
fi

if [[ -e "${ENV}" ]] ; then
  source "${ENV}"
else
  echo "File not found: ${ENV}"
  echo "See the LDAP documentation for details on populating this file with your settings"
  exit 1
fi

API_USER_CREATION="${URL}/api/admin/customer/1/apiPermissionSettings"

if [[ ${ENABLE} = true ]] ; then
  if [[ ${DISABLE} = true ]] ; then
    print_usage
  else
    curl ${CURL_OPTS} \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -X POST \
      -d '{"allowApiUserCreation":true}' \
      ${API_USER_CREATION} | ${JSON_FILTER}
    exit ${?}
  fi

elif [[ ${DISABLE} = true ]] ; then
  if [[ ${ENABLE} = true ]] ; then
    print_usage
  else
    curl ${CURL_OPTS} \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -X POST \
      -d '{"allowApiUserCreation":false}' \
      ${API_USER_CREATION} | ${JSON_FILTER}
    exit ${?}
  fi

else
  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${API_USER_CREATION} | ${JSON_FILTER}
  exit ${?}
fi
