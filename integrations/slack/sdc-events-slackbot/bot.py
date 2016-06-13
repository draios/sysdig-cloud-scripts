#!/usr/bin/env python
# coding=utf8
import sys
import time
import re
import argparse
import logging

from slackclient import SlackClient
from sdcclient import SdcClient

###############################################################################
# Basic slack interface class
###############################################################################
class SlackWrapper(object):
    inputs = []

    def __init__(self, slack_client, slack_id):
        self.slack_client = slack_client
        self.slack_id = slack_id

        self.slack_users = {}
        for user in self.slack_client.server.users:
            self.slack_users[user.id] = user.name
        self.resolved_channels = {}
        self.resolved_users = {}

    def resolve_channel(self, channel):
        channel_type = channel[0]
        if channel in self.resolved_channels:
            return self.resolved_channels[channel]
        elif channel_type == 'C':
            channel_info = self.slack_client.api_call("channels.info", channel=channel)
            logging.debug("channels.info channel=%s response=%s" % (channel, channel_info))
            if channel_info["ok"]:
                self.resolved_channels[channel] = channel_info['channel']['name']
                return self.resolved_channels[channel]
            else:
                return channel
        elif channel_type == 'G':
            group_info = self.slack_client.api_call("groups.info", channel=channel)
            logging.debug("groups.info channel=%s response=%s" % (channel, group_info))
            if group_info["ok"]:
                self.resolved_channels[channel] = group_info['group']['name']
                return self.resolved_channels[channel]
            else:
                return channel
        elif channel_type == 'D':
            return "Direct"
        else:
            return channel

    def resolve_user(self, user):
        user_type = user[0]
        if user in self.resolved_users:
            return self.resolved_users[user]
        elif user_type == 'U':
            user_info = self.slack_client.api_call("users.info", user=user)
            logging.debug("users.info user=%s response=%s" % (user, user_info))
            if user_info["ok"]:
                self.resolved_users[user] = user_info["user"]["name"]
                return self.resolved_users[user]
            else:
                return user
        elif user_type == 'B':
            # Right now we are not able to resolve bots
            # see https://api.slack.com/methods/bots.info
            return "bot"
        else:
            return user

    def say(self, channelid, text):
        message_json = {'type': 'message', 'channel': channelid, 'text': text}
        self.slack_client.server.send_to_websocket(message_json)

    def listen(self):
        self.inputs = []
        while True:
            try:
                rv = self.slack_client.rtm_read()
                time.sleep(.1)
            except KeyboardInterrupt:
                sys.exit(0)
            except Exception:
                rv = []

            for reply in rv:
                logging.debug("Received from Slack: %s", reply)
                if 'type' not in reply:
                    continue

                if reply['type'] != 'message':
                    continue

                if 'subtype' in reply and reply['subtype'] not in ('bot_message'):
                    continue

                if 'channel' not in reply:
                    continue

                if 'user' in reply and reply['user'] == self.slack_id:
                    continue

                if 'text' in reply and len(reply['text']) > 0:
                    txt = reply['text']
                elif 'attachments' in reply and 'fallback' in reply['attachments'][0]:
                    txt = reply['attachments'][0]['fallback']
                else:
                    continue
                if 'user' in reply:
                    user_id = reply['user']
                elif 'bot_id' in reply:
                    user_id = reply['bot_id']
                else:
                    user_id = None

                self.inputs.append((user_id, reply['channel'], txt.strip(' \t\n\r')))

            if len(self.inputs) != 0:
                return

###############################################################################
# Chat endpoint class
###############################################################################

SLACK_BUDDY_HELP = """
*Available commands*:
_!help_ - shows this message
_!post_event description [name=<eventname> [severity=<1 to 7>] [some_tag_key=some_tag_value]_ - sends a custom event to Sysdig Cloud
_!auto_events enable|disable_ - when enabled, all message in this channel will be automatically converted to a Sysdig Cloud event

*Examples*:
_!post_event load balancer going down for maintenance_. The text you type will be converted into the custom event description'
_!post_event my test event name="test 1" severity=5_
_!post_event name="test 2" severity=1_

"""

class SlackBuddy(SlackWrapper):
    inputs = []
    PARAMETER_MATCHER = re.compile(u"([a-z]+) ?= ?(?:\u201c([^\u201c]*)\u201d|\"([^\"]*)\"|([^\s]+))")

    def __init__(self, sdclient, slack_client, slack_id):
        self._sdclient = sdclient
        super(SlackBuddy, self).__init__(slack_client, slack_id)
        self.auto_events_channels = set()

    def handle_help(self, channel):
        self.say(channel, SLACK_BUDDY_HELP)

    def post_event(self, user, channel, evt):
        tags = evt.get('tags', {})
        tags['channel'] = self.resolve_channel(channel)
        tags['user'] = self.resolve_user(user)
        tags['source'] = 'slack'
        evt['tags'] = tags

        logging.info("Posting event=%s channel=%s" % (repr(evt), channel))
        return self._sdclient.post_event(**evt)

    def handle_auto_events_cmd(self, channel, line):
        channel_type = channel[0]
        if channel_type not in ('C', 'G'):
            self.say(channel, "This feature works only on channels")
            return

        subcmd = line.strip()
        if subcmd == "enable":
            self.auto_events_channels.add(channel)
            self.say(channel, "auto-events enabled, every message in this channel will be converted in an event from now on.")
        elif subcmd == "disable":
            self.auto_events_channels.remove(channel)
            self.say(channel, "auto-events disabled.")
        else:
            self.say(channel, "wrong syntax, argument can be `enable` or `disable`")

    def handle_post_event(self, user, channel, line, silent=False):
        purged_line = self.strip_message(re.sub(self.PARAMETER_MATCHER, "", line))
        event_from = self.resolve_channel(channel)
        if event_from == "Direct":
            event_from = self.resolve_user(user)
        event = {
            "name": "Slack Event From " + event_from,
            "description": purged_line,
            "severity": 6,
            "tags": {}
        }
        for item in re.finditer(self.PARAMETER_MATCHER, line):
            key = item.group(1)
            value = item.group(2)
            if value is None:
                value = item.group(3)
            if value is None:
                value = item.group(4)
            if key in ("name", "description"):
                event[key] = value
            elif key == "severity":
                try:
                    severity = int(value)
                except ValueError:
                    severity = 0

                if severity >= 1 and severity <= 7:
                    event[key] = int(value)
                else:
                    self.say(channel, "invalid severity, it must be a number from 1 (highest) to 7 (lowest)")
                    return
            else:
                event["tags"][key] = value

        res, error = self.post_event(user, channel, event)
        if res:
            if not silent:
                self.say(channel, 'Event posted successfully')
        else:
            self.say(channel, 'Error posting event: ' + error)
            logging.error('Error posting event: ' + error)

    @classmethod
    def strip_message(cls, s):
        return s.strip(' \t\n\r?!.')

    def run(self):
        while True:
            self.listen()

            for user, channel, txt in self.inputs:
                channel_type = channel[0]
                logging.debug("Received message user=%s channel=%s line=%s" % (user, channel, txt))
                if txt.startswith('!help'):
                    self.handle_help(channel)
                elif txt.startswith('!post_event'):
                    self.handle_post_event(user, channel, self.strip_message(txt[len("!post_event"):]))
                elif txt.startswith("!auto_events"):
                    self.handle_auto_events_cmd(channel, self.strip_message(txt[len("!auto_events"):]))
                elif channel in self.auto_events_channels:
                    self.handle_post_event(user, channel, txt, silent=True)
                elif channel_type == 'D':
                    self.say(channel, "Unknown command!")
                    self.handle_help(channel)

def LogLevelFromString(level):
    return getattr(logging, level.upper())

###############################################################################
# Entry point
###############################################################################
def init():
    parser = argparse.ArgumentParser(description='Sysdig Cloud Slack bot.')
    parser.add_argument('--sysdig-api-token', dest='sdc_token', required=True, type=str, help='Sysdig API Token')
    parser.add_argument('--slack-token', dest='slack_token', required=True, type=str, help='Slack Token')
    #parser.add_argument('--auto-events', '-a', dest='auto_events', action='store_true', help='When enabled, every message received by the bot will be converted to a Sysdig Cloud event')
    parser.add_argument('--log-level', dest='log_level', type=LogLevelFromString, help='Logging level, available values: debug, info, warning, error')
    args = parser.parse_args()

    logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", level=args.log_level)
    # requests generates too noise on information level
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    
    #
    # Instantiate the SDC client and Retrieve the SDC user information to make sure we have a valid connection
    #
    sdclient = SdcClient(args.sdc_token)

    #
    # Make a connection to the slack API
    #
    sc = SlackClient(args.slack_token)
    sc.rtm_connect()

    sinfo = sc.api_call('auth.test')
    slack_id = sinfo['user_id']

    #
    # Start talking!
    #
    dude = SlackBuddy(sdclient, sc, slack_id)
    #dude.auto_events = args.auto_events
    dude.run()

if __name__ == "__main__":
    init()
