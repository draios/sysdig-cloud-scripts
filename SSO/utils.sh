#!/usr/bin/env bash

function get_settings_id() {
  SETTINGS_ID=`curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${SETTINGS_ENDPOINT} | jq '.authenticationSettings | .[] | select(.type=="'"${SSO_KEYWORD}"'") | .id'`
}

# Should be run after get_settings_id so ${SETTINGS_ID} might by set
function exit_if_no_settings_id() {
  if [[ -z "${SETTINGS_ID}" ]] ; then
    echo "No ${SSO_KEYWORD} settings are set"
    echo "Run for further info: ./${SCRIPT_NAME} -h"
    echo
    exit 0
  fi
}

function get_active_settings_type() {
  ACTIVE_SETTINGS_TYPE=`curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${ACTIVE_ENDPOINT} | jq '.activeSettings | .type'`
}

function get_settings_version() {
  VERSION=`curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${SETTINGS_ENDPOINT} | jq '.authenticationSettings | .[] | select(.type=="'"${SSO_KEYWORD}"'") | .version'`
}

function set_as_active_setting() {
  get_settings_id
  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X PUT \
    ${ACTIVE_ENDPOINT}/${SETTINGS_ID} | ${JSON_FILTER}
}

function disable_current_sso_auth_if_needed() {
  if [[ ${ACTIVE_SETTINGS_TYPE} == *${SSO_KEYWORD}* ]]; then
    curl ${CURL_OPTS} \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -X DELETE \
      ${ACTIVE_ENDPOINT} | ${JSON_FILTER}
  fi
}

function delete_settings() {
  get_settings_id
  exit_if_no_settings_id
  get_active_settings_type
  disable_current_sso_auth_if_needed

  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X DELETE \
    ${SETTINGS_ENDPOINT}/${SETTINGS_ID} | ${JSON_FILTER}
}

function get_settings() {
  get_settings_id
  exit_if_no_settings_id

  get_active_settings_type
  if [[ ${ACTIVE_SETTINGS_TYPE} == *${SSO_KEYWORD}* ]]; then
    echo "${SSO_KEYWORD} is selected as auth method"
  else
    echo "${SSO_KEYWORD} is not selected as auth method"
  fi

  curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -X GET \
    ${SETTINGS_ENDPOINT}/${SETTINGS_ID} | ${JSON_FILTER}
}
