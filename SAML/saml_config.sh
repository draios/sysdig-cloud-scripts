#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o si:a:m:dnh --long set,idp:,app:,meta:,nocreate,delete,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
SET=false
DELETE=false
HELP=false
IDP=""
APP=""
AUTOCREATE=true
METADATA_URL=""

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./saml_config.sh [OPTIONS]"
  echo
  echo "Affect SAML login settings for your Sysdig software platform installation"
  echo
  echo "If no OPTIONS are specified, the current login config settings are printed"
  echo
  echo "Options:"

  echo "  -s | --set                 Set the current SAML login config"
  echo "  -i | --idp okta|onelogin   Use SAML config options based on a supported IDP"
  echo "  -a | --app monitor|secure  Set SAML config for the given Sysdig application"
  echo "  -m | --meta 'URL'          Metadata URL (provided from IDP-side configuration)"
  echo "  -n | --nocreate            Disable auto-creation of user records upon first successful auth"
  echo "  -d | --delete              Delete the current SAML login config"
  echo "  -h | --help                Print this Usage output"
  exit 1
}

while true; do
  case "$1" in
    -s | --set ) SET=true; shift ;;
    -i | --idp ) IDP="$2"; shift; shift ;;
    -a | --app ) APP="$2"; shift; shift ;;
    -m | --meta ) METADATA_URL="$2"; shift; shift ;;
    -n | --nocreate ) AUTOCREATE="false"; shift ;;
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
  echo "See the SAML documentation for details on populating this file with your settings"
  exit 1
fi

if [ "$APP" = "monitor" ] ; then
  APP_URL="$URL/api/admin/customer/${CUSTOMER_ID}/saml"
elif [ "$APP" = "secure" ] ; then
  APP_URL="$URL/api/admin/customer/${CUSTOMER_ID}/saml?product=SDS"
else
  echo "Must specify the Sysdig App whose SAML configuration will be viewed/set"
  echo
  print_usage
fi

if [ $SET = true ] ; then
  if [ $DELETE = true ] ; then
    print_usage
  else
    if [ "$IDP" = "okta" ] ; then
      SIGNED_ASSERTION="true"
      VALIDATE_SIGNATURE="true"
      VERIFY_DESTINATION="true"
      EMAIL_PARAM="email"
    elif [ "$IDP" = "onelogin" ] ; then
      SIGNED_ASSERTION="false"
      VALIDATE_SIGNATURE="true"
      VERIFY_DESTINATION="true"
      EMAIL_PARAM="User.email"
    else
      echo "IDP is unknown/unspecified. Contact Sysdig Support for assistance."
      exit 1
    fi
    if [ -z "$METADATA_URL" ] ; then
      echo "Must specify a metadata URL (provided from IDP-side configuration)"
      echo
      print_usage
    fi
    curl $CURL_OPTS \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_TOKEN" \
        -X POST \
        -d '{"metadataUrl": "'"${METADATA_URL}"'", "signedAssertion": "'"${SIGNED_ASSERTION}"'", "validateSignature": "'"${VALIDATE_SIGNATURE}"'", "emailParameter": "'"${EMAIL_PARAM}"'", "createUserOnLogin": "'"${AUTOCREATE}"'" }' \
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
