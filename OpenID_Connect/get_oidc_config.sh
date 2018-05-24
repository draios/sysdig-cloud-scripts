#!/bin/bash
DEFAULT_SDC_API_URL='https://app.sysdigcloud.com'

SYSDIG_PRODUCT=""
PRODUCT_URL=""
while [ "z${SYSDIG_PRODUCT}" = "z" ] ; do
  echo -n "Specify Product (monitor or secure) (required): "
  read SYSDIG_PRODUCT
  while [[ "$SYSDIG_PRODUCT" != "monitor" && "$SYSDIG_PRODUCT" != "secure" ]]
   do
     echo -n "Specify Product (monitor or secure) (required): "
     read SYSDIG_PRODUCT
   done
  if [ "$SYSDIG_PRODUCT" == 'monitor' ];then
      PRODUCT_URL='openid'
  elif [ "$SYSDIG_PRODUCT" == secure ]; then
    PRODUCT_URL='openid/?product=SDS'
    fi
done

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

CUSTOMER_ID=""
while [ "z${CUSTOMER_ID}" = "z" ] ; do
  echo -n "Enter Customer ID # (required): "
  read CUSTOMER_ID
done

set -x

curl -k -v ''"${SDC_API_URL}"'/api/admin/customer/'"${CUSTOMER_ID}"'/'"${PRODUCT_URL}"''/ \
     -H 'Authorization: Bearer '"${API_TOKEN}"''
