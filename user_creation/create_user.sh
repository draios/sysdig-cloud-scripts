#!/usr/bin/env bash
set -uo pipefail

OPTS=`getopt -o edu:f:l:p:h --long enable,disable,username:,firstname:,lastname:,password:,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then
  echo "Failed parsing options." >&2
  exit 1
fi

ENV="./env.sh"
ENABLE=false
DISABLE=false
USERNAME=""
FIRSTNAME=""
LASTNAME=""
PASSWORD=""
HELP=false

eval set -- "$OPTS"

function print_usage() {
  echo "Usage: ./create_user.sh [OPTION]"
  echo
  echo "Create a user record, or change permissions for API-based user creation"
  echo
  echo "General options:"
  echo "  -h | --help             Print this Usage output"
  echo
  echo "Options for changing permissions:"
  echo "  -e | --enable           Enable API-based user creation (it's enabled by default)"
  echo "  -d | --disable          Disable API-based user creation"
  echo
  echo "Options for creating a user record:"
  echo "  -u | --username         Username for the user record to create"
  echo "  -p | --password         Password for the user record to create"
  echo "  -f | --firstname        (optional) First name for the user record to create"
  echo "  -l | --lastname         (optional) Last name for the user record to create"
  exit 1
}

while true; do
  case "$1" in
    -e | --enable ) ENABLE=true; shift ;;
    -d | --disable ) DISABLE=true; shift ;;
    -u | --username ) USERNAME="$2"; shift; shift ;;
    -p | --password ) PASSWORD="$2"; shift; shift ;;
    -f | --firstname ) FIRSTNAME="$2"; shift; shift ;;
    -l | --lastname ) LASTNAME="$2"; shift; shift ;;
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

# Check for HTTP response code on the app_attributes endpoint. If we get a 404, we'll
# need to know that later because it means it's never been set and hence is at its
# default.
HTTP_RESP=`curl ${CURL_OPTS} -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $API_TOKEN" \
  -X GET \
  $URL/api/admin/appAttribute/apiUserCreation`
if [ $? != 0 ] ; then
  echo "Unable to access $URL. Review settings in env.sh and try again."
  exit 1
fi

if [ $ENABLE = true -o $DISABLE = true ] ; then
  if [ -n "$USERNAME" -o -n "$PASSWORD" -o -n "$FIRSTNAME" -o -n "$LASTNAME" ] ; then
    print_usage
  elif [ $ENABLE = true -a $DISABLE = true ] ; then
    print_usage
  else
    if [ $ENABLE = true ] ; then
      VALUE="true"
    else
      VALUE="false"
    fi

    if [ "$HTTP_RESP" = "404" ] ; then
      echo "No prior setting found. Attempting to set for the first time."
      curl ${CURL_OPTS} \
        -H "Authorization: Bearer $API_TOKEN" \
	-H "Content-Type: application/json; charset=UTF-8" \
	-X POST \
	--data-binary '{"id": "apiUserCreation", "value": "'"${VALUE}"'"}' \
	$URL/api/admin/appAttribute | ${JSON_FILTER}
    else
      CURRENT_CONFIG=`curl ${CURL_OPTS} \
        -H "Authorization: Bearer $API_TOKEN" \
        -X GET \
        $URL/api/admin/appAttribute/apiUserCreation`
      VERSION=`echo ${CURRENT_CONFIG} | sed 's/^.*,"version"://' | sed 's/,".*$//'`
      curl ${CURL_OPTS} \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json; charset=UTF-8" \
        -X PUT \
        --data-binary '{"id": "apiUserCreation", "value": "'"${VALUE}"'","version":"'"${VERSION}"'"}' \
	$URL/api/admin/appAttribute/apiUserCreation | ${JSON_FILTER}
    fi
  fi

elif [ -n "$USERNAME" ] ; then
  if [ $ENABLE = true -o $DISABLE = true -o -z "$PASSWORD" ] ; then
    print_usage
  else
    JSON='{"username": "'"${USERNAME}"'","password":"'"${PASSWORD}"'","customer":{"id":"'${CUSTOMER_ID}'"}'
    if [ -n "$FIRSTNAME" ] ; then
      JSON=${JSON}',"firstName": "'"${FIRSTNAME}"'"'
    fi
    if [ -n "$LASTNAME" ] ; then
      JSON=${JSON}',"lastName": "'"${LASTNAME}"'"'
    fi
    JSON=${JSON}'}'
    curl $CURL_OPTS \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json; charset=UTF-8" \
      -X POST \
      --data-binary "${JSON}" \
      $URL/api/admin/user
  fi

elif [ "$HTTP_RESP" = "404" ] ; then
  echo "Settings are at initial defaults (creation of users via API is enabled)"

else
  curl $CURL_OPTS \
    -H "Authorization: Bearer $API_TOKEN" \
    -X GET \
    $URL/api/admin/appAttribute/apiUserCreation | ${JSON_FILTER}
fi
