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
SSO_KEYWORD="ldap"
SCRIPT_NAME=`basename "$0"`

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./${SCRIPT_NAME} [OPTION]"
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

function get_settings_id() {
  SETTINGS_ID=`curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    ${SETTINGS_ENDPOINT} | jq '.authenticationSettings | .[] | select(.type=="'"${SSO_KEYWORD}"'") | .id'`
}

# Should be run after get_settings_id so $SETTINGS_ID might by set
function exit_if_no_settings_id() {
  if [ -z "$SETTINGS_ID" ] ; then
    echo "No ${SSO_KEYWORD} settings are set"
    echo "Run for further info: ./${SCRIPT_NAME} -h"
    echo
    exit 0
  fi
}

function get_active_settings_type() {
  ACTIVE_SETTINGS_TYPE=`curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    $ACTIVE_ENDPOINT | jq '.activeSettings | .type'`
}

function get_settings_version() {
  VERSION=`curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    ${SETTINGS_ENDPOINT} | jq '.authenticationSettings | .[] | select(.type=="'"${SSO_KEYWORD}"'") | .version'`
}

function set_as_active_setting() {
  get_settings_id
  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X PUT \
    $ACTIVE_ENDPOINT/$SETTINGS_ID | ${JSON_FILTER}
}

function set_settings() {
  get_settings_id
  if [ -z "$SETTINGS_ID" ] ; then
    sed -i "s/\"version\".*$/\"version\": 1,/" ${SETTINGS_JSON}
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      -X POST \
      -d @$SETTINGS_JSON \
      $SETTINGS_ENDPOINT | ${JSON_FILTER}
  else
    get_settings_version
    sed -i "s/\"version\".*$/\"version\": ${VERSION},/" ${SETTINGS_JSON}
    cat ${SETTINGS_JSON}
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      -X PUT \
      -d @$SETTINGS_JSON \
      $SETTINGS_ENDPOINT/$SETTINGS_ID | ${JSON_FILTER}
  fi
  set_as_active_setting
}

function disable_current_sso_auth_if_needed() {
  if [[ $ACTIVE_SETTINGS_TYPE == *$SSO_KEYWORD* ]]; then
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -X DELETE \
      $ACTIVE_ENDPOINT | ${JSON_FILTER}
  fi
}

function delete_settings() {
  get_settings_id
  exit_if_no_settings_id
  get_active_settings_type
  disable_current_sso_auth_if_needed

  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X DELETE \
    $SETTINGS_ENDPOINT/$SETTINGS_ID | ${JSON_FILTER}
}

function get_settings() {
  get_settings_id
  exit_if_no_settings_id

  get_active_settings_type
  if [[ $ACTIVE_SETTINGS_TYPE == *$SSO_KEYWORD* ]]; then
    echo "${SSO_KEYWORD} is selected as auth method"
  else
    echo "${SSO_KEYWORD} is not selected as auth method"
  fi

  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    $SETTINGS_ENDPOINT/$SETTINGS_ID | ${JSON_FILTER}
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

SETTINGS_ENDPOINT="${URL}/api/admin/auth/settings"
ACTIVE_ENDPOINT="${URL}/api/auth/settings/active"

if [ $SET = true ] ; then
  if [ $DELETE = true ] ; then
    print_usage
  fi
  set_settings
elif [ $DELETE = true ] ; then
  if [ $SET = true ] ; then
    print_usage
  fi
  delete_settings
else
  get_settings
fi

exit $?
