#!/bin/sh
DEFAULT_SDC_API_URL='https://app.sysdigcloud.com'

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

ISSUER_URL=""
while [ "z${ISSUER_URL}" = "z" ] ; do
  echo -n "Enter Issuer URL from OpenID Provider (required): "
  read ISSUER_URL
done

CLIENT_ID=""
while [ "z${CLIENT_ID}" = "z" ] ; do
  echo -n "Enter Client ID from OpenID Provider (required): "
  read CLIENT_ID
done

CLIENT_SECRET=""
while [ "z${CLIENT_SECRET}" = "z" ] ; do
  echo -n "Enter Client Secret from OpenID Provider (required): "
  read CLIENT_SECRET
done

CUSTOMER_ID=""
while [ "z${CUSTOMER_ID}" = "z" ] ; do
  echo -n "Enter Customer ID # (required): "
  read CUSTOMER_ID
done

OPENID_CONFIG='{"issuer":"'"${ISSUER_URL}"'","clientId":"'"${CLIENT_ID}"'","clientSecret":"'"${CLIENT_SECRET}"'","metadataDiscovery":true}'

echo $OPENID_CONFIG

set -x

curl -XPOST -k -s ''"${SDC_API_URL}"'/api/admin/customer/'"${CUSTOMER_ID}"'/openid/' \
     -H 'Content-Type: application/json; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     -H 'Authorization: Bearer '"${API_TOKEN}"'' \
     --data-binary ''"${OPENID_CONFIG}"'' --compressed
