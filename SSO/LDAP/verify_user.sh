#!/usr/bin/env bash
set -uo pipefail

ENV="../env.sh"
USER_SPECIFIED=false
USERNAME=""
HELP=false

function print_usage() {
  echo "Usage: ./verify_user -u USERNAME"
  echo
  echo "Verify a user could login via current LDAP Authentication configuration"
  echo
  echo "Options:"
  echo "  -u USERNAME   Name of the directory user to query via LDAP"
  echo "  -h            Print this Usage output"
  exit 1
}

eval "set -- $(getopt hu: "$@")"
while [[ $# -gt 0 ]] ; do
    case "${1}" in
      (-h) HELP=true ;;
      (-u) USER_SPECIFIED=true; USERNAME="${2}"; shift;;
      (--) shift; break;;
      (-*) echo "${0}: error - unrecognized option ${1}" 1>&2; exit 1;;
      (*)  break;;
    esac
    shift
done

if [[ ${HELP} = true ]] ; then
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

if [[ ${USER_SPECIFIED} = true ]] ; then
  curl -f ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    $URL/api/admin/ldap/settings/verify/"${USERNAME}" | ${JSON_FILTER}

  RET=$?
  if [[ ${RET} -ne 0 ]] ; then
    echo "Could not verify user \"${USERNAME}\". Check LDAP login config settings and/or system log."
    exit ${RET}
  else
    exit 0
  fi

else
  print_usage
fi
