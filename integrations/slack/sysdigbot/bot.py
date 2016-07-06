#!/usr/bin/env python
# coding=utf8
# Copyright (c) 2016 Draios inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import sys
import time
import re
import argparse
import logging
import os

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
            except Exception as ex:
                logging.warning("Error on Slack WebSocket: %s" % str(ex))
                
                for t in [2**i for i in range(12)]:
                    logging.info("Reconnecting to Slack in %d seconds..." % t)
                    time.sleep(t)
                    if self.slack_client.rtm_connect():
                        logging.info("Successfully reconnected to Slack")
                        break
                else:
                    logging.error("Cannot connect to Slack, terminating...")
                    sys.exit(1)


            for reply in rv:
                logging.debug("Data from Slack: %s", repr(reply))
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
*Usage*:

Just type something, it will be automatically converted to a Sysdig Cloud event:

_load balancer going down for maintenance_

You can customize all the event fields in this way:

_Turning down API server severity=3_
_Turning down API server severity=3 name=manteinance_

or add custom tags:

_Turning down API server severity=3 name=manteinance region=us-east-1_

*Available commands*:
`!help` - Shows this message.
`[!post_event] description [name=<eventname>] [severity=<1 to 7>] [some_tag_key=some_tag_value]` - Sends a custom event to Sysdig Cloud. Note, the `!post_event` prefix is only necessary if bot.py was launched with the `--no-auto-events` parameter. 

"""

class SlackBuddy(SlackWrapper):
    inputs = []
    PARAMETER_MATCHER = re.compile(u"([a-z_]+) ?= ?(?:\u201c([^\u201c]*)\u201d|\"([^\"]*)\"|([^\s]+))")
    SLACK_LINK_MATCHER = re.compile('<http(.*?)>')

    def __init__(self, sdclient, slack_client, slack_id, quiet):
        self._sdclient = sdclient
        self._quiet = quiet
        self.auto_events_message_sent = set()
        super(SlackBuddy, self).__init__(slack_client, slack_id)


    def links_2_mkdown(self, str):
        res = str
        sllinks = re.finditer(self.SLACK_LINK_MATCHER, str)
        for l in sllinks:
            txt = l.group()
            span = l.span()
            if '|' in txt:
                # Link is in the format <http(s)://xxx|desc>. Conver it to [desc](http(s)://xxx)
                components = txt[1:-1].split("|")
                newlink = '[%s](%s)' % (components[1], components[0])
                res = res[:span[0]] + newlink + res[span[1]:]
            else:
                # Link is in the format <http(s)://xxx>. Just remove the '<' and '>'
                res = res[:span[0]] + txt[1:-1] + res[span[1]:]

            # Done converting the first link in the message. Recursively convert the following ones
            return self.links_2_mkdown(res)
        return res

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

    def handle_post_event(self, user, channel, line, silent=False):
        line = self.links_2_mkdown(line)
        purged_line = re.sub(self.PARAMETER_MATCHER, "", line).strip(' \t\n\r?!.')
        event_from = self.resolve_channel(channel)
        if event_from == "Direct":
            event_from = self.resolve_user(user)
        else:
            if self._quiet:
                silent = True
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
                self.say(channel, 'Event successfully posted to Sysdig Cloud.')
        else:
            self.say(channel, 'Error posting event: ' + error)
            logging.error('Error posting event: ' + error)

    def run(self):
        while True:
            self.listen()

            for user, channel, txt in self.inputs:
                channel_type = channel[0]
                logging.debug("Received message user=%s channel=%s line=%s" % (user, channel, txt))
                if txt.startswith('!help'):
                    self.handle_help(channel)
                elif txt.startswith('!post_event'):
                    self.handle_post_event(user, channel, txt[len("!post_event"):].strip(' \t\n\r?!.'))
                elif self.auto_events:
                    ch = self.resolve_channel(channel)
                    if user in self.auto_events_message_sent:
                        #not first message from user
                        if ch != "Direct":
                            # Post silently in channels after confirming once, to avoid noise
                            self.handle_post_event(user, channel, txt, silent=True)
                        else: 
                            self.handle_post_event(user, channel, txt)
                    else:
                        #first message from user
                        self.handle_post_event(user, channel, txt)
                        if ch == "Direct":
                            self.say(channel, "By the way, you have the option to customize title, description, severity and other event properties. Type `!help` to learn how to do it.")
                        elif (ch != "Direct" and not self._quiet):
                            self.say(channel, "To reduce channel noise, Sysdigbot will now stop confirming events automatically posted on chats from this user.")
                        self.auto_events_message_sent.add(user)
                elif channel_type == 'D':
                    self.say(channel, "Unknown command!")
                    self.handle_help(channel)

def LogLevelFromString(level):
    return getattr(logging, level.upper())

###############################################################################
# Entry point
###############################################################################
def init():
    sdc_token = None
    try:
        sdc_token = os.environ["SYSDIG_API_TOKEN"]
    except KeyError:
        pass
    slack_token = None
    try:
        slack_token = os.environ["SLACK_TOKEN"]
    except KeyError:
        pass
    parser = argparse.ArgumentParser(description='Sysdigbot: the Sysdig Cloud Slack bot.')
    parser.add_argument('--sysdig-api-token', dest='sdc_token', required=(sdc_token is None), default=sdc_token, type=str, help='Sysdig API Token, you can use also SYSDIG_API_TOKEN environment variable to set it')
    parser.add_argument('--slack-token', dest='slack_token', required=(slack_token is None), default=slack_token, type=str, help='Slack Token, you can use also SLACK_TOKEN environment variable to set it')
    parser.add_argument('--quiet', dest='quiet', action='store_true', help='Prevents the bot from printing output on channels, which is useful to avoid any kind of channel pollution')
    parser.add_argument('--no-auto-events', dest='auto_events', action='store_false', help='By default Sysdigbot converts every message in a channel in a Sysdig Cloud event, this flag disables it')
    parser.add_argument('--log-level', dest='log_level', type=LogLevelFromString, help='Logging level, available values: debug, info, warning, error')
    args = parser.parse_args()

    logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", level=args.log_level)
    # requests generates too noise on information level
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.debug("Starting Sysdigbot, config=%s", repr(args))

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
    dude = SlackBuddy(sdclient, sc, slack_id, args.quiet)
    dude.auto_events = args.auto_events
    dude.run()

if __name__ == "__main__":
    init()
