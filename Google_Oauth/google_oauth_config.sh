#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o su:i:e:r:a:m:dh --long set,issuerurl:,clientid:,clientsecret:,redirecturl:,alloweddomains:,delete,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
SET=false
DELETE=false
HELP=false
CLIENT_ID=""
CLIENT_SECRET=""
ALLOWED_DOMAINS="[]"
REDIRECT_URL=""
SSO_KEYWORD="google-oauth"
SCRIPT_NAME=`basename "$0"`

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./${SCRIPT_NAME} [OPTIONS]"
  echo
  echo "Affect OpenID Connect login settings for your Sysdig software platform installation"
  echo
  echo "If no OPTIONS are specified, the current login config settings are printed"
  echo
  echo "Options:"

  echo "  -s | --set                 Set the current Google Oauth configuration"
  echo "  -i | --clientid            Client ID from Google config"
  echo "  -e | --clientsecret        Client Secret from Google config"
  echo "  -a | --alloweddomains      [\"Comma\", \"separated\", \"list\"] of allowed domains"
  echo "  -r | --redirecturl         Allowed redirect URL"
  echo "  -d | --delete              Delete the current OpenID Connect login config"
  echo "  -h | --help                Print this Usage output"
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

function check_provider_variables() {
  if [ -z "$CLIENT_ID" -o -z "$CLIENT_SECRET" ] ; then
    echo "To change settings, you must enter values for Client ID, and Client Secret"
    echo
    print_usage
  fi
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
  check_provider_variables
  get_settings_id
  if [ -z "$SETTINGS_ID" ] ; then
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{
        "authenticationSettings": {
          "type": "'"${SSO_KEYWORD}"'",
          "settings": {
            "redirectUrl":"'"${REDIRECT_URL}"'",
            "allowedDomains": '"${ALLOWED_DOMAINS}"',
            "clientId":"'"${CLIENT_ID}"'",
            "clientSecret":"'"${CLIENT_SECRET}"'"}}}' \
      $SETTINGS_ENDPOINT | ${JSON_FILTER}
  else
    get_settings_version
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      -X PUT \
      -d '{
        "authenticationSettings": {
          "type": "'"${SSO_KEYWORD}"'",
          "settings": {
            "redirectUrl":"'"${REDIRECT_URL}"'",
            "allowedDomains":'"${ALLOWED_DOMAINS}"',
            "clientId":"'"${CLIENT_ID}"'",
            "clientSecret":"'"${CLIENT_SECRET}"'"}}}' \
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
    -s | --set ) SET=true; shift ;;
    -i | --clientid ) CLIENT_ID="$2"; shift; shift ;;
    -e | --clientsecret ) CLIENT_SECRET="$2"; shift; shift ;;
    -a | --alloweddomains ) ALLOWED_DOMAINS="$2"; shift; shift ;;
    -r | --redirecturl ) REDIRECT_URL="$2"; shift; shift ;;
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
  echo "See the OpenID Connect documentation for details on populating this file with your settings"
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
