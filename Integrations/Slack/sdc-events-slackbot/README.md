# sdc-events-slackbot
A script to post events to Sysdig Cloud from slack.

# Install Instructions
1. `ip install slackclient sdcclient` 
2. Go to this page to create a new Slack bot user https://my.slack.com/services/new/bot
3. Once you are done with the bot creation wizard, the Slack API token will be available under _Integration Settings_. Make a copy of it
4. Browse to https://app.sysdigcloud.com/#/settings/user and copy the Sysdig Cloud API Token that you find under _Sysdig Cloud API_
5. `python bot.py <sysdig_token> <slack_token>`
6. You can now send messages to the bot. They will be posted to Sysdig Cloud as events and they will appear on charts.
