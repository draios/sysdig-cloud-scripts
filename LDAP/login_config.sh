#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o s:dh --long set:,delete,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
SET=false
SETTINGS_JSON=""
DELETE=false
HELP=false

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./login_config [OPTION]"
  echo
  echo "Affect LDAP login settings for your Sysdig software platform installation"
  echo
  echo "If no OPTION is specified, the current login config settings are printed"
  echo
  echo "Options:"
  echo "  -s | --set  JSON_FILE   Set the current LDAP login config to the contents of JSON_FILE"
  echo "  -d | --delete           Delete the current LDAP login config"
  echo "  -h | --help             Print this Usage output"
  exit 1
}

while true; do
  case "$1" in
    -s | --set ) SET=true; SETTINGS_JSON="$2"; shift; shift ;;
    -d | --delete ) DELETE=true; shift ;;
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
  if [ $DELETE = true ] ; then
    print_usage
  else
    if [ ! -e $SETTINGS_JSON ] ; then
      echo "Settings file \"$SETTINGS_JSON\" does not exist. No settings were changed."
      exit 1
    fi
    cat $SETTINGS_JSON | ${JSON_FILTER} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      curl $CURL_OPTS \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_TOKEN" \
        -X POST \
        -d @$SETTINGS_JSON \
        $URL/api/admin/ldap/settings
      exit $?
    else
      echo "\"$SETTINGS_JSON\" contains invalid JSON. No settings were changed."
      exit 1
    fi
  fi

elif [ $DELETE = true ] ; then
  if [ $SET = true ] ; then
    print_usage
  else
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -X DELETE \
      $URL/api/admin/ldap/settings
    exit $?
  fi

else
  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    $URL/api/admin/ldap/settings | ${JSON_FILTER}
  exit $?
fi
