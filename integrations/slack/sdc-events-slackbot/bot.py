#!/usr/bin/env python
# coding=utf8
import sys
import time
import json
import re

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

                self.inputs.append((reply['channel'], txt.strip(' \t\n\r')))

            if len(self.inputs) != 0:
                return

###############################################################################
# Chat endpoint class
###############################################################################
class SlackBuddy(SlackWrapper):
    inputs = []
    PARAMETER_MATCHER = re.compile(u"([a-z]+) ?= ?(?:\u201c([^\u201c]*)\u201d|\"([^\"]*)\"|([^\s]+))")

    def __init__(self, sdclient, slack_client, slack_id):
        self._sdclient = sdclient
        super(SlackBuddy, self).__init__(slack_client, slack_id)

    def handle_help(self, channel):
        self.say(channel, '*Basic syntax*: just type something (e.g. _load balancer going down for maintenance_). The text you type will be converted into a custom event')
        self.say(channel, '*Advanced syntax*: !post_event name, description (optional) and severity (optional) can be specified separately. For example:\n    _!event name=test 1, desc=test event, severity=5_\n    _!event name=test 2, severity=1_')

    def post_event(self, channel, evt):
        tags = evt.get('tags', {})
        tags['source'] = 'slack'
        evt['tags'] = tags

        res = self._sdclient.post_event(**evt)
        if res[0]:
            self.say(channel, 'Event posted')
        else:
            self.say(channel, 'Error posting event: ' + res[1])

    def handle_post_event(self, channel, line):
        purged_line = re.sub(self.PARAMETER_MATCHER, "", line).strip(' \t\n\r?!.')
        event = {
            "name": "Slack Event",
            "description": purged_line,
            "severity": 5,
            "tags": {}}
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
                event[key] = int(value)
            else:
                event["tags"][key] = value
        self.post_event(channel, event)

    def run(self):
        while True:
            self.listen()

            for inpt in self.inputs:
                if inpt[1].startswith('!help'):
                    self.handle_help(inpt[0])
                elif inpt[1].startswith('!post_event'):
                    self.handle_post_event(inpt[0], inpt[1][len("!post_event"):].strip(' \t\n\r?!.'))
                elif self.auto_events:
                    self.handle_post_event(inpt[0], inpt[1])

###############################################################################
# Entry point
###############################################################################
def init():
    if len(sys.argv) < 3:
        print('usage: %s <sysdig-token> <slack-token>' % sys.argv[0])
        sys.exit(1)
    else:
        sdc_token = sys.argv[1]
        slack_token = sys.argv[2]

    auto_events=False
    if len(sys.argv) > 3 and sys.argv[3] == "--auto-events":
        auto_events = True
    #
    # Instantiate the SDC client and Retrieve the SDC user information to make sure we have a valid connection
    #
    sdclient = SdcClient(sdc_token)

    #
    # Make a connection to the slack API
    #
    sc = SlackClient(slack_token)
    sc.rtm_connect()

    slack_id = sc.api_call('auth.test')['user_id']

    #
    # Start talking!
    #
    dude = SlackBuddy(sdclient, sc, slack_id)
    dude.auto_events = auto_events
    dude.run()

if __name__ == "__main__":
    init()
