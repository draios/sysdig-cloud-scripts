#!/usr/bin/env bash
set -uo pipefail

ENV="../env.sh"
UTILS="../utils.sh"

SET=false
DELETE=false
HELP=false
IDP=""
AUTOCREATE=true
METADATA_URL=""
SSO_KEYWORD="saml"
SCRIPT_NAME=`basename "${0}"`

function print_usage() {
  echo "Usage: ./${SCRIPT_NAME} [OPTIONS]"
  echo
  echo "Affect SAML login settings for your Sysdig software platform installation"
  echo
  echo "If no OPTIONS are specified, the current login config settings are printed"
  echo
  echo "Options:"

  echo "  -s    Set the specified SAML login config"
  echo "  -i    Use SAML config options based on a supported IDP"
  echo "  -m    Metadata URL (provided from IDP-side configuration)"
  echo "  -n    Disable auto-creation of user records upon first successful auth"
  echo "  -d    Delete the current SAML login config"
  echo "  -h    Print this Usage output"
  exit 1
}

function set_provider_variables() {
  if [[ -z "${IDP}" ]] ; then
    echo "IDP is unspecified. Contact Sysdig Support for assistance."
    echo
    print_usage
  fi

  if [[ ${IDP} = "okta" ]] ; then
    SIGNED_ASSERTION="true"
    VALIDATE_SIGNATURE="true"
    VERIFY_DESTINATION="true"
    EMAIL_PARAM="email"
  elif [[ ${IDP} = "onelogin" ]] ; then
    SIGNED_ASSERTION="false"
    VALIDATE_SIGNATURE="true"
    VERIFY_DESTINATION="true"
    EMAIL_PARAM="User.email"
  else
    echo "IDP is unknown. Contact Sysdig Support for assistance."
    exit 1
  fi

  if [[ -z "${METADATA_URL}" ]] ; then
    echo "Must specify a metadata URL (provided from IDP-side configuration)"
    echo
    print_usage
  fi
}

function set_settings() {
  set_provider_variables
  get_settings_id
  if [[ -z "${SETTINGS_ID}" ]] ; then
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{
        "authenticationSettings": {
          "type": "'"${SSO_KEYWORD}"'",
          "settings": {
            "metadataUrl": "'"${METADATA_URL}"'",
            "enabled": "'"true"'",
            "signedAssertion": "'"${SIGNED_ASSERTION}"'",
            "validateSignature": "'"${VALIDATE_SIGNATURE}"'",
            "verifyDestination": "'"${VERIFY_DESTINATION}"'",
            "emailParameter": "'"${EMAIL_PARAM}"'",
            "createUserOnLogin": "'"${AUTOCREATE}"'" }}}' \
      ${SETTINGS_ENDPOINT} | ${JSON_FILTER}
  else
    get_settings_version
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -X PUT \
      -d '{
        "authenticationSettings": {
          "type": "'"${SSO_KEYWORD}"'",
          "version": "'"${VERSION}"'",
          "settings": {
            "metadataUrl": "'"${METADATA_URL}"'",
            "enabled": "'"true"'",
            "signedAssertion": "'"${SIGNED_ASSERTION}"'",
            "validateSignature": "'"${VALIDATE_SIGNATURE}"'",
            "verifyDestination": "'"${VERIFY_DESTINATION}"'",
            "emailParameter": "'"${EMAIL_PARAM}"'",
            "createUserOnLogin": "'"${AUTOCREATE}"'" }}}' \
      ${SETTINGS_ENDPOINT}/${SETTINGS_ID} | ${JSON_FILTER}
  fi
  set_as_active_setting
}


eval "set -- $(getopt sdhni:m: "$@")"
while [[ $# -gt 0 ]] ; do
    case "${1}" in
      (-s) SET=true ;;
      (-d) DELETE=true ;;
      (-h) HELP=true ;;
      (-n) AUTOCREATE="false" ;;
      (-i) IDP="${IDP}${2}"; shift;;
      (-m) METADATA_URL="${METADATA_URL}${2}"; shift;;
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
  echo "See the SAML documentation for details on populating this file with your settings"
  exit 1
fi

if [[ -e "${UTILS}" ]] ; then
  source "${UTILS}"
else
  echo "File not found: ${UTILS}"
  echo "See the SAML documentation for details on populating this file with your settings"
  exit 1
fi

SETTINGS_ENDPOINT="${URL}/api/admin/auth/settings"
ACTIVE_ENDPOINT="${URL}/api/auth/settings/active"

if [[ ${SET} = true ]] ; then
  if [[ ${DELETE} = true ]] ; then
    print_usage
  fi
  set_settings
elif [[ ${DELETE} = true ]] ; then
  if [[ ${SET} = true ]] ; then
    print_usage
  fi
  delete_settings
else
  get_settings
fi

exit $?
