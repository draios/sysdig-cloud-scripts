# sdc-events-slackbot
A script that allows you to post custom events directly to Sysdig Cloud through chats with a Slack bot.

Note, this script utilizes the Sysdig Cloud python client (https://github.com/draios/python-sdc-client), a wrapper for the Sysdig Cloud REST API. 

# Install Instructions
1. `pip install -r requirements.txt` 
2. Go to this page to create a new Slack bot user: https://my.slack.com/services/new/bot
3. Once you are done with the bot creation wizard, the Slack API token will be available under _Integration Settings_. Make a copy of it
4. Browse to https://app.sysdigcloud.com/#/settings/user and copy the Sysdig Cloud API Token that you find under _Sysdig Cloud API_
5. `python bot.py --sysdig-api-token <sysdig_token> --slack-token <slack_token>`

Alternatively you can use our provided Dockerfile:

1. `docker build -t sdc-bot .`
2. `docker run -d --name sdc-bot -e SYSDIG_API_TOKEN=<sysdig_token> -e SLACK_TOKEN=<slack_token> sdc-bot`

# Usage

You can now send messages to the bot or invite the bot to Slack channels. Then you can use the bot syntax to use it.

If you launch it with `--auto-events` parameter, the bot will translate each received messages into a Sysdig Cloud event. This behavior can be handy if there are other bots in the channel that post automatic notifications. They will be posted to Sysdig Cloud as events and they will appear on charts.

## Available commands

* *!help* - shows this message
* *!post_event description [name=<eventname> [severity=<1 to 7>] [some_tag_key=some_tag_value]* - sends a custom event to Sysdig Cloud

## Examples

*!post_event load balancer going down for maintenance*. The text you type will be converted into the custom event description'

*!post_event my test event name="test 1" severity=5*

*!post_event name="test 2" severity=1*

# Improvements

- Add more commands. For example, it would be very cool to have a `!get_data` or `!get_alert_notification` that mimic the behavior of the Python client API
- Better parsing from bot messages. For example, we can recognize when a github/jenkins bot posts a message, and automatically dissect the message into name/description/tags
