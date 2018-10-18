#!/usr/bin/env bash

#
# Set this to the Sysdig Monitor API Token value shown in the Sysdig UI under
# Settings->User Profile when logged in as the "Super" Admin User. For
# information on locating this user, see the following article:
#
# https://support.sysdig.com/hc/en-us/articles/115004951443-Locating-the-Super-Admin-User
#
export API_TOKEN="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

#
# Set this to the URL through which you access your Sysdig application UI.
#
export URL="https://10.0.0.1"

#
# This should be set to your customer ID number, which will almost always be 1. If
# you are unsure, see the following article for instructions to verify:
# https://support.sysdig.com/hc/en-us/articles/115005848823-Your-Customer-Number
#
export CUSTOMER_ID="1"

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
# If Python is installed on the host where you're running these helper scripts, this
# will enable some extra features like pretty printing of JSON output and checking if
# JSON inputs are syntactically valid. If Python is not installed, it uses a no-op
# "cat" instead and you'll get unformatted output and you'll get HTTP error codes
# if you try to POST invalid JSON.
#
if hash python 2>/dev/null ; then
  export JSON_FILTER="python -m json.tool"
else
  export JSON_FILTER="cat"
fi
