#!/usr/bin/env bash
set -uo pipefail

OPTS=$(getopt -o r:t:h --long role:,team:,help -n 'parse-options' -- "$@")

if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
#TODO enumerate values
TEAM_NAME=""
USER_ROLE=""
HELP=false

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./update_default_user_role.sh [OPTIONS]"
  echo
  echo "Update the default user role for the specified team"
  echo
  echo "If no OPTION is specified, available user roles and teams are displayed"
  echo
  echo "General options:"
  echo "  -h | --help             Print this Usage output"
  echo
  echo "Options for updating a team:"
  echo "  -t | --team             Team name"
  echo "  -r | --role             Default user"
  exit 1
}

while true; do
  case "$1" in
    -t | --team ) TEAM_NAME="$2"; shift; shift ;;
    -r | --role ) USER_ROLE="$2"; shift; shift ;;
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
  echo "See the README for details on populating this file with your settings"
  echo "(https://github.com/draios/sysdig-cloud-scripts/blob/master/user_creation/README.md)"
  exit 1
fi

function print_roles {
  INFO=$(curl ${CURL_OPTS} \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -X GET \
    "$URL/api/customer/roles" | jq -r '.[] | "\(.displayName), \(.role)"')
  echo -e "User roles:\n"
  column -t -s ',' <<< "${INFO}"
}

function print_info {
  print_roles
  echo ""
  INFO=$(curl ${CURL_OPTS} \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -X GET \
    "$URL/api/teams/light" | jq -r '.teams | .[] | "\(.name), \(.defaultTeamRole)"')
  echo -e "Team names and current default user roles:\n"
  column -t -s ',' <<< "${INFO}"

}

function get_team {
  TEAM_NAME="$1"
  curl ${CURL_OPTS} \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -X GET \
    "$URL/api/teams/light"  | jq -r --arg TEAM_NAME "${TEAM_NAME}" \
    '.teams | .[] | select(.name == $TEAM_NAME)'
}

function update_team {
  TEAM="$1"
  USER_ROLE="$2"

  TEAM_ID=$(jq '.id' <<< "${TEAM}")
  TEAM_UPDATED=$(jq --arg ROLE "${USER_ROLE}" '.defaultTeamRole |= $ROLE' <<< "${TEAM}")
  curl --fail ${CURL_OPTS} \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -X PUT \
    --data-binary "${TEAM_UPDATED}" \
    "$URL/api/teams/${TEAM_ID}" | jq
}

if ! command -v column > /dev/null || ! command -v jq > /dev/null; then
  echo "This script requires 'jq' and 'column' commands to run properly"
  exit 1
fi

if [ -z "${TEAM_NAME}" ] ; then
  print_info
  exit 0
fi

if [ -z "${USER_ROLE}" ] ; then
  echo -e "Please specify a role with --role option.\n"
  print_roles
  exit 0
fi

TEAM=$(get_team "${TEAM_NAME}")
update_team "${TEAM}" "${USER_ROLE}"
exit $?
