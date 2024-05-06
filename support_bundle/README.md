# Please run the support bundle with the valid API-TOKEN
  Replace for your current namespace.

export API_TOKEN="xxxxx-xxxxx-xxxx-xxxxx"

./get_support_bundle.sh -a $API_TOKEN -n sysdigcloud


# Workaround for uses cases where the access to the API endpoint is limited/restricted.

Please, before to execute the script,  run these two command to confirm that your port-forwarding and API_TOKEN are working as expected.

1 - Enable Port-forwarding for svc/sysdigcloud-api

kubectl port-forward service/sysdigcloud-api -n sysdigcloud 8080

2 - (From another linux terminal) call the API license using your Secure API_TOKEN.

curl -s -k 'http://127.0.0.1:8080/api/license' \
-H 'Authorization: Bearer xxxxxx-xxxxx-xxxxx-xxxxxx' -H 'Content-Type: application/json'

If this is working , you should get an output like this :

{"license":{"version":1,"customer":"xxxx-xxxx-sysdig","maxAgents":5000,"maxTeams":-1,"secureEnabled":true,"trackingCustomerId":"xxxx0000nAxxx","plan":null,"expirationDate":1726876800000,"expirationDateDefined":true}}

If you got a error like this below, could mean that the Secure api token is not recognized for some reason like a typo or wrong token, and the script will fail.

{"timestamp":1713168791762,"status":401,"error":"Unauthorized","message":"Bad credentials","path":"/api/license"}


3 - Run the script attached (be sure that the port-forwarded is running in a separated terminal)

Example:
(-d will execute with debug, -s 168h will collect logs from last 7 days)

bash -x ./get_support_bundle_local_api.sh -n sysdigcloud -a "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx" -d -s 168h

