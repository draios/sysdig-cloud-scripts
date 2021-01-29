#!/usr/bin/env bash
set -uo pipefail

ENV="../../env.sh"

SET=false
SETTINGS_JSON=""
FORCESYNC=false
REPORT=false
DELETE=false
HELP=false

function print_usage() {
  echo "Usage: ./mapping_config.sh [OPTION]"
  echo
  echo "Affect LDAP mapping settings for your Sysdig software platform installation"
  echo
  echo "If no OPTION is specified, the current mapping config settings are printed"
  echo
  echo "Options:"
  echo "  -s JSON_FILE   Set the current LDAP mapping config to the contents of JSON_FILE"
  echo "  -f             Force an immediate sync"
  echo "  -r             Print the report of the most recent sync operation"
  echo "  -d             Delete the current LDAP mapping config"
  echo "  -h             Print this Usage output"
  exit 1
}

eval "set -- $(getopt dhfrs: "$@")"
while [[ $# -gt 0 ]] ; do
    case "${1}" in
      (-d) DELETE=true ;;
      (-h) HELP=true ;;
      (-f) FORCESYNC=true ;;
      (-r) REPORT=true ;;
      (-s) SET=true; SETTINGS_JSON="${SETTINGS_JSON}${2}"; shift;;
      (--) shift; break;;
      (-*) echo "${0}: error - unrecognized option ${1}" 1>&2; exit 1;;
      (*)  break;;
    esac
    shift
done

if [[ $HELP = true ]] ; then
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

SYNC_LDAP_ENDPOINT="${URL}/api/admin/ldap/syncLdap"
SYNC_SETTINGS_ENDPOINT="${URL}/api/admin/ldap/settings/sync"
SYNC_REPORT_ENDPOINT="${URL}/api/admin/ldap/syncReport"

function force_sync() {
  echo "Forcing sync"
  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X PUT \
    ${SYNC_LDAP_ENDPOINT}
  exit ${?}
}

if [[ ${SET} = true ]] ; then
  if [[ ${DELETE} = true || ${REPORT} = true ]] ; then
    print_usage
  else
    if [[ ! -e ${SETTINGS_JSON} ]] ; then
      echo "Settings file \"${SETTINGS_JSON}\" does not exist. No settings were changed."
      exit 1
    fi
    if [[ ${?} -eq 0 ]] ; then
      echo "JSON checked successfully"
      curl ${CURL_OPTS} \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -X POST \
        -d @${SETTINGS_JSON} \
        ${URL}/api/admin/ldap/settings/sync | ${JSON_FILTER}
      if [[ ${?} -eq 0 ]] ; then
        if [[ ${FORCESYNC} = true ]] ; then
          force_sync
        else
          exit 0
        fi
      else
        exit ${?}
      fi
    else
      echo "\"${SETTINGS_JSON}\" contains invalid JSON. No settings were changed."
      exit 1
    fi
  fi

elif [[ ${DELETE} = true ]] ; then
  if [[ ${SET} = true || ${REPORT} = true ]] ; then
    print_usage
  else
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -X DELETE \
      ${SYNC_SETTINGS_ENDPOINT} | ${JSON_FILTER}
    if [[ ${?} -eq 0 ]] ; then
      if [[ ${FORCESYNC} = true ]] ; then
        force_sync
      else
        exit 0
      fi
    else
      exit ${?}
    fi
  fi

elif [[ ${REPORT} = true ]] ; then
  if [[ ${SET} = true || ${DELETE} = true || ${FORCESYNC} = true ]] ; then
    print_usage
  else
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -X GET \
      ${SYNC_REPORT_ENDPOINT} | ${JSON_FILTER}
    exit ${?}
  fi

elif [[ ${FORCESYNC} = true ]] ; then
  if [[ ${SET} = true || ${DELETE} = true || ${REPORT} = true ]] ; then
    print_usage
  else
    force_sync
  fi

else
  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${SYNC_SETTINGS_ENDPOINT} | ${JSON_FILTER}
  exit ${?}
fi
