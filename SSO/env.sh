#!/usr/bin/env bash

#
# Set this to "Super" Admin User Sysdig Monitor or Sysdig Secure API Token value.
# You will find it at "User Profile" under "Settings" page. Depending on the token you
# type here Monitor or Secure settings will be changed.
#
export API_TOKEN="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

#
# Set this to the URL through which you access your Sysdig application UI.
#
export URL="https://10.0.0.1"

#
# Set options used in other scripts that invoke curl. We've set these to what we think
# are sensible defaults:
#
# -s
#    Silent mode, to make outputs brief. If you're debugging and want verbose outputs,
#    you might want to change this to -v.
#
# -k
#    Leave this set to "-k" to allow curl to connect to your Sysdig API even if a self-
#    signed certificate is in use (the default in a Sysdig software platform install).
#
# -w \n
#    Print a newline after curl prints responses. This will make the Sysdig platform's
#    JSON responses easier to read.
#
export CURL_OPTS="-s -k -w \n"

#
# Install jq command line tool to run the script. This should be achieved by running:
# sudo apt install jq
# Or similar command, depending your OS
#

if hash jq 2>/dev/null ; then
  export JSON_FILTER="jq"
else
  echo "Please install jq tool to run this command"
  echo "This should be achieved by running 'sudo apt install jq' or similar command"
  echo
  exit 1
fi
