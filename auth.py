#!/usr/bin/env python3

import logging
import os
import sys

class Authentication():
    def __init__(self):
        cstring = os.environ.get("TWITCH_ID")
        if cstring is None:
            logging.error("Secret not found.")
            sys.exit(1)
        else:
            credentials = cstring.split(":")

        if len(credentials) < 2:
            logging.error("Secret not found.")
            sys.exit(1)
        else:
            self.id,self.secret = credentials
            print(self.id,self.secret)

