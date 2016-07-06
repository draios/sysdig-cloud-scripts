# sysdigbot
Use this python script to spin up a Sysdigbot, a chat bot that allows you to interact with Sysdig Cloud though Slack.

Currently Sysdigbot allows you to post custom events directly to Sysdig Cloud through chats in Slack. These chats can come from you and your teammates, or from any other app that you have integrated with Slack (think: code deploys, support tickets, marketing events, etc.) 

Check out the Sysdigbot [launch blog post](https://sysdig.com/blog/universal-slack-event-router/) for more info.

Note, this script utilizes the [Sysdig Cloud python client](https://github.com/draios/python-sdc-client), a wrapper for the Sysdig Cloud REST API. 

# Install Instructions

1. Create a [new Slack bot user](https://my.slack.com/services/new/bot) called "Sysdigbot" (or whatever you want), and note your Slack API token. 
2. Go to the [User Settings page](https://app.sysdigcloud.com/#/settings/user) in Sysdig Cloud, and note your Sysdig Cloud API Token (which, to be clear, is different from your Access Key).
3. Pull and run the Sysdigbot container from Docker Hub:  

`docker run [-d] --name sysdig-bot -e SYSDIG_API_TOKEN=<sysdig_token> -e SLACK_TOKEN=<slack_token> sysdig/sysdig-bot [--help] [--quiet] [--no-auto-events] [--log-level LOG_LEVEL]`

## Manual Installation

1. `pip install -r requirements.txt` 
2. `python bot.py --sysdig-api-token <sysdig_token> --slack-token <slack_token>`

Alternatively you can use our provided Dockerfile:

1. `docker build -t sysdig-bot .`
2. `docker run [-d] --name sysdig-bot -e SYSDIG_API_TOKEN=<sysdig_token> -e SLACK_TOKEN=<slack_token> sysdig/sysdig-bot [--help] [--quiet] [--no-auto-events] [--log-level LOG_LEVEL]`

# Usage

Sysdigbot will automatically translate each message it hears on Slack into a Sysdig Cloud event:  
`description [name=<eventname>] [severity=<1 to 7>] [some_tag_key=some_tag_value]`

You can send messages directly to Sysdigbot, or invite Sysdigbot to any Slack channel to listen in. This channel listening behavior can be handy if there are other bots in the channel that post automatic notifications. 

## Available commands

* `!help` - Shows this message.
* `[!post_event] description [name=<eventname>] [severity=<1 to 7>] [some_tag_key=some_tag_value]` - Sends a custom event to Sysdig Cloud. Note, the `!post_event` prefix is only necessary if you launch bot.py with the `--no-auto-events` parameter. 

## Examples

* `!post_event load balancer going down for maintenance`

* `!post_event my test event name="test 1" severity=5`

* `!post_event name="test 2" severity=1 tag=value`

# Improvements

If you like any of these ideas and want to see them, or if you have any cool ideas of your own, let us know at support@sysdig.com - thanks!

- Add more commands. For example, it would be very cool to have a `!get_data` or `!get_alert_notification` that mimic the behavior of the Python client API
- Better parsing from bot messages. For example, we can recognize when a github/jenkins bot posts a message, and automatically dissect the message into name/description/tags
- Hosted Sysdigbot
