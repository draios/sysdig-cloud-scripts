#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o s:h --long set:,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
SET=false
SETTINGS_JSON=""
HELP=false

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./create_user [OPTION]"
  echo
  echo "Create a user record in advance of their possible login via LDAP"
  echo
  echo "Options:"
  echo "  -s | --set  JSON_FILE   Create the user described in the contents of JSON_FILE"
  echo "  -h | --help             Print this Usage output"
  exit 1
}

while true; do
  case "$1" in
    -s | --set ) SET=true; SETTINGS_JSON="$2"; shift; shift;;
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

if [ $SET = true ] ; then
  if [ ! -e $SETTINGS_JSON ] ; then
    echo "Settings file \"$SETTINGS_JSON\" does not exist. No user was created."
  exit 1
  fi
  cat $SETTINGS_JSON | ${JSON_FILTER} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    curl $CURL_OPTS \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $API_TOKEN" \
      -X POST \
      -d @$SETTINGS_JSON \
      $URL/api/admin/user
    exit $?
  else
    echo "\"$SETTINGS_JSON\" contains invalid JSON. No user was created."
    exit 1
  fi

else
  print_usage
fi
