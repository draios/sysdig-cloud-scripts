#!/bin/sh
exec python bot.py --sysdig-api-token $SYSDIG_API_TOKEN --slack-token $SLACK_TOKEN $*
