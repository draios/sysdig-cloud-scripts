#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o su:i:e:m:dh --long set,issuerurl:,clientid:,clientsecret:,delete,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="../env.sh"
UTILS="../utils.sh"

SET=false
DELETE=false
HELP=false
ISSUER_URL=""
CLIENT_ID=""
CLIENT_SECRET=""
SSO_KEYWORD="openid"
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

  echo "  -s | --set                 Set the current OpenID Connect login config"
  echo "  -u | --issuerurl           Issuer URL from your OpenID Provider config"
  echo "  -i | --clientid            Client ID from your OpenID Provider config"
  echo "  -e | --clientsecret        Client Secret from your OpenID Provider config"
  echo "  -d | --delete              Delete the current OpenID Connect login config"
  echo "  -h | --help                Print this Usage output"
  exit 1
}

function check_provider_variables() {
  if [ -z "$ISSUER_URL" -o -z "$CLIENT_ID" -o -z "$CLIENT_SECRET" ] ; then
    echo "To change settings, you must enter values for Issuer URL, Client ID, and Client Secret"
    echo
    print_usage
  fi
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
            "issuer":"'"${ISSUER_URL}"'",
            "clientId":"'"${CLIENT_ID}"'",
            "clientSecret":"'"${CLIENT_SECRET}"'",
            "metadataDiscovery":true}}}' \
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
          "version": "'"$VERSION"'",
          "settings": {
            "issuer":"'"${ISSUER_URL}"'",
            "clientId":"'"${CLIENT_ID}"'",
            "clientSecret":"'"${CLIENT_SECRET}"'",
            "metadataDiscovery":true}}}' \
      $SETTINGS_ENDPOINT/$SETTINGS_ID | ${JSON_FILTER}
  fi
  set_as_active_setting
}

while true; do
  case "$1" in
    -s | --set ) SET=true; shift ;;
    -u | --issuerurl ) ISSUER_URL="$2"; shift; shift ;;
    -i | --clientid ) CLIENT_ID="$2"; shift; shift ;;
    -e | --clientsecret ) CLIENT_SECRET="$2"; shift; shift ;;
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

if [ -e "$UTILS" ] ; then
  source "$UTILS"
else
  echo "File not found: $UTILS"
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
