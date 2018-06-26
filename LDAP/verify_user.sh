#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o u:h --long user:,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
USER_SPECIFIED=false
USERNAME=""
HELP=false

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./verify_user -u USERNAME"
  echo
  echo "Verify a user could login via current LDAP Authentication configuration"
  echo
  echo "Options:"
  echo "  -u | --user  USERNAME   Name of the directory user to query via LDAP"
  echo "  -h | --help             Print this Usage output"
  exit 1
}

while true; do
  case "$1" in
    -u | --user ) USER_SPECIFIED=true; USERNAME="$2"; shift; shift;;
    -h | --help ) HELP=true; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ $HELP = true ] ; then
  print_usage
fi

if [ $# -gt 0 ] ; then
  echo "Excess command-line arguments detected. Exiting."
  echo
  print_usage
fi

if [ -e "$ENV" ] ; then
  source "$ENV"
else
  echo "File not found: $ENV"
  echo "See the LDAP documentation for details on populating this file with your settings"
  exit 1
fi

if [ $USER_SPECIFIED = true ] ; then
  curl -f $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    $URL/api/admin/ldap/settings/verify/"${USERNAME}"
  RET=$?
  if [ ${RET} -ne 0 ] ; then
    echo "Could not verify user \"${USERNAME}\". Check LDAP login config settings and/or system log."
    exit $RET
  else
    exit 0
  fi

else
  print_usage
fi
