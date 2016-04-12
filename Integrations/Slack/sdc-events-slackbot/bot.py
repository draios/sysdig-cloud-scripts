#!/usr/bin/env python
import sys
import time
import requests
import json
import re

sys.path.insert(0, '../python-sdc-client/')
from slackclient import SlackClient
from sdcclient import SdcClient

SYSDIG_URL = 'https://app-staging2.sysdigcloud.com'

###############################################################################
# Basic slack interface class
###############################################################################
class SlackWrapper(object):
    inputs = []

    def __init__(self, slack_client, slack_id):
        self.slack_client = slack_client
        self.slack_id = slack_id

        self.slack_users = {}
        for u in self.slack_client.server.users:
            self.slack_users[u.id] = u.name

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
            except:
                rv = []


            for reply in rv:
                if 'channel' in reply:
                    if 'type' in reply and reply['type'] == 'message':
                        # only accept direct messages
                        if reply['channel'][0] == 'D':
                            if not 'user' in reply:
                                continue

                            if reply['user'] != self.slack_id:
                                self.last_channel_id = reply['channel']

                                if not 'text' in reply:
                                    continue
                                
                                txt = reply['text']
                                self.inputs.append(txt.strip(' \t\n\r?!.'))

            if len(self.inputs) != 0:
                return

###############################################################################
# Chat endpoint class
###############################################################################
class SlackBuddy(SlackWrapper):
    inputs = []

    def __init__(self, sdclient, slack_client, slack_id):
        self._sdclient = sdclient
        super(SlackBuddy, self).__init__(slack_client, slack_id)

    def print_help(self):
        self.say(self.last_channel_id, '*Basic syntax*: just type something (e.g. _load balancer going down for maintenance_). The text you type will be converted into an alert with severity 6 (info)')
        self.say(self.last_channel_id, '*Advanced syntax*: name, description (optional) and severity (optional) can be specified separately. For example:\n    _name=test 1, desc=test event, severity=5_\n    _name=test 2, severity=1_')

    def parse_line(self, line):
        components = line.split(",")

        if len(components) == 1:
            self._sdclient.post_event(line)
            self.say(self.last_channel_id, 'event posted')
        else:
            name = ''
            desc = ''
            severity = 6
            for c in components:
                tpl = c.strip(' \t\n\r?!.').split("=")
                if tpl[0]== 'name':
                    name = tpl[1]
                if tpl[0]== 'desc':
                    desc = tpl[1]
                if tpl[0]== 'severity':
                    severity = int(tpl[1])

            if name == '':
                self.say('error: name cannot be empty')
                return

            self._sdclient.post_event(name, desc, severity)
            self.say(self.last_channel_id, 'event posted')


    def run(self):
        while True:
            self.listen()

            for i in self.inputs:
                if i == 'help':
                    self.print_help()
                else:
                    self.parse_line(i)

###############################################################################
# Entry point
###############################################################################
def init():
    if len(sys.argv) != 3:
        print 'usage: %s <sysdig-token> <slack-token>' % sys.argv[1]
        sys.exit(0)
    else:
        sdc_token = sys.argv[1]
        slack_token = sys.argv[2]

    #
    # Instantiate the SDC client and Retrieve the SDC user information to make sure we have a valid connection
    #
    sdclient = SdcClient(sdc_token, SYSDIG_URL)

    #
    # Make a connection to the slack API
    #
    sc = SlackClient(slack_token)
    sc.rtm_connect()

    slack_id = json.loads(sc.api_call('auth.test'))['user_id']

    #
    # Start talking!
    #
    dude = SlackBuddy(sdclient, sc, slack_id)
    dude.run()

init()
