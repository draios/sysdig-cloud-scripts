# sdc-events-slackbot
A script that allows you to post custom events directly to Sysdig Cloud through chats with a Slack bot.

Note, this script utilizes the Sysdig Cloud python client (https://github.com/draios/python-sdc-client), a wrapper for the Sysdig Cloud REST API. 

# Install Instructions
1. `pip install -r requirements.txt` 
2. Go to this page to create a new Slack bot user: https://my.slack.com/services/new/bot
3. Once you are done with the bot creation wizard, the Slack API token will be available under _Integration Settings_. Make a copy of it
4. Browse to https://app.sysdigcloud.com/#/settings/user and copy the Sysdig Cloud API Token that you find under _Sysdig Cloud API_
5. `python bot.py <sysdig_token> <slack_token>`

# Usage

You can now send messages to the bot or invite the bot to Slack channels. By default, the bot will translate each received messages into a Sysdig Cloud event. This behavior can be handy if there are other bots in the channel that post automatic notifications

They will be posted to Sysdig Cloud as events and they will appear on charts.

# Improvements

- Add more commands. For example, it would be very cool to have a `!get_data` or `!get_alert_notification` that mimic the behavior of the Python client API
- Better parsing from bot messages. For example, we can recognize when a github/jenkins bot posts a message, and automatically dissect the message into name/description/tags
