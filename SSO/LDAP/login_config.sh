#!/usr/bin/env bash
set -uo pipefail

ENV="../env.sh"
UTILS="../utils.sh"

SET=false
SETTINGS_JSON=""
DELETE=false
HELP=false
SSO_KEYWORD="ldap"
SCRIPT_NAME=`basename "${0}"`

function print_usage() {
  echo "Usage: ./${SCRIPT_NAME} [OPTION]"
  echo
  echo "Affect LDAP login settings for your Sysdig software platform installation"
  echo
  echo "If no OPTION is specified, the current login config settings are printed"
  echo
  echo "Options:"
  echo "  -s JSON_FILE    Set the current LDAP login config to the contents of JSON_FILE"
  echo "  -d              Delete the current LDAP login config"
  echo "  -h              Print this Usage output"
  exit 1
}

function set_settings() {
  get_settings_id
  if [[ -z "${SETTINGS_ID}" ]] ; then
    sed -i "s/\"version\".*$/\"version\": 1,/" ${SETTINGS_JSON}
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -X POST \
      -d @${SETTINGS_JSON} \
      ${SETTINGS_ENDPOINT} | ${JSON_FILTER}
  else
    get_settings_version
    sed -i "s/\"version\".*$/\"version\": ${VERSION},/" ${SETTINGS_JSON}
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -X PUT \
      -d @${SETTINGS_JSON} \
      ${SETTINGS_ENDPOINT}/${SETTINGS_ID} | ${JSON_FILTER}
  fi
  set_as_active_setting
}

eval "set -- $(getopt dhs: "$@")"
while [[ $# -gt 0 ]] ; do
    case "${1}" in
      (-d) DELETE=true ;;
      (-h) HELP=true ;;
      (-s) SET=true; SETTINGS_JSON="${SETTINGS_JSON}${2}"; shift;;
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

if [[ -e "${UTILS}" ]] ; then
  source "${UTILS}"
else
  echo "File not found: ${UTILS}"
  echo "See the LDAP documentation for details on populating this file with your settings"
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
