#!/bin/bash
DEFAULT_SDC_API_URL='https://app.sysdigcloud.com'
DEFAULT_SIGNED_ASSERTION='true'
DEFAULT_EMAIL_PARAM='email'

echo -n "Enter API URL [${DEFAULT_SDC_API_URL}]: "
read SDC_API_URL
if [ "z${SDC_API_URL}" = "z" ] ; then
  SDC_API_URL=${DEFAULT_SDC_API_URL}
fi

API_TOKEN=""
while [ "z${API_TOKEN}" = "z" ] ; do
  echo -n "Enter Admin API Token (required): "
  read API_TOKEN
done

METADATA_URL=""
while [ "z${METADATA_URL}" = "z" ] ; do
  echo -n "Enter Metadata URL from IDP (required): "
  read METADATA_URL
done

echo -n "Require signed SAML assertion? [${DEFAULT_SIGNED_ASSERTION}]: "
read SIGNED_ASSERTION
if [ "z${SIGNED_ASSERTION}" = "z" ]; then
  SIGNED_ASSERTION="${DEFAULT_SIGNED_ASSERTION}"
fi

CUSTOMER_ID=""
while [ "z${CUSTOMER_ID}" = "z" ] ; do
  echo -n "Enter Customer ID # (required): "
  read CUSTOMER_ID
done

echo -n "Email parameter name [${DEFAULT_EMAIL_PARAM}]: "
read EMAIL_PARAM
if [ "z${EMAIL_PARAM}" = "z" ]; then
  EMAIL_PARAM="${DEFAULT_EMAIL_PARAM}"
fi

set -x

curl -XPOST -v -k ''"${SDC_API_URL}"'/api/admin/customer/'"${CUSTOMER_ID}"'/saml/' \
           -H 'Content-Type: application/json; charset=UTF-8' \
           -H 'Accept: application/json, text/javascript, */*; q=0.01' \
           -H 'Authorization: Bearer '"${API_TOKEN}"'' \
           --data-binary '{"metadataUrl": "'"${METADATA_URL}"'", "signedAssertion": "'"${SIGNED_ASSERTION}"'", "emailParameter": "'"${EMAIL_PARAM}"'" }' --compressed
