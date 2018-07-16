#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o su:i:e:a:m:dh --long set,issuerurl:,clientid:,clientsecret:,app:,delete,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
SET=false
DELETE=false
HELP=false
ISSUER_URL=""
CLIENT_ID=""
CLIENT_SECRET=""
APP=""

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./oidc_config.sh [OPTIONS]"
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
  echo "  -a | --app monitor|secure  Set OpenID Connect config for the given Sysdig application"
  echo "  -d | --delete              Delete the current OpenID Connect login config"
  echo "  -h | --help                Print this Usage output"
  exit 1
}

while true; do
  case "$1" in
    -s | --set ) SET=true; shift ;;
    -u | --issuerurl ) ISSUER_URL="$2"; shift; shift ;;
    -i | --clientid ) CLIENT_ID="$2"; shift; shift ;;
    -e | --clientsecret ) CLIENT_SECRET="$2"; shift; shift ;;
    -a | --app ) APP="$2"; shift; shift ;;
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

if [ "$APP" = "monitor" ] ; then
  APP_URL="$URL/api/admin/customer/${CUSTOMER_ID}/openid"
elif [ "$APP" = "secure" ] ; then
  APP_URL="$URL/api/admin/customer/${CUSTOMER_ID}/openid?product=SDS"
else
  echo "Must specify the Sysdig App whose OpenID Connect configuration will be viewed/set"
  echo
  print_usage
fi

if [ $SET = true ] ; then
  if [ $DELETE = true ] ; then
    print_usage
  else
    if [ -z "$ISSUER_URL" -o -z "$CLIENT_ID" -o -z "$CLIENT_SECRET" ] ; then
      echo "To change settings, you must enter values for Issuer URL, Client ID, and Client Secret"
      echo
      print_usage
    fi
    curl $CURL_OPTS \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_TOKEN" \
        -X POST \
        -d '{"issuer":"'"${ISSUER_URL}"'", "clientId":"'"${CLIENT_ID}"'", "clientSecret":"'"${CLIENT_SECRET}"'", "metadataDiscovery":true}' \
        "$APP_URL" | ${JSON_FILTER}
    exit $?
  fi

elif [ $DELETE = true ] ; then
  if [ $SET = true ] ; then
    print_usage
  else
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -X DELETE \
      "$APP_URL"
    exit $?
  fi

else
  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    "$APP_URL" | ${JSON_FILTER}
  exit $?
fi
