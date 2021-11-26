#!venv/bin/python3
#
# Server component of demo app
#
# This provides an example of how to provide your own custom features
# outside of the 'entrance' package.
#
# Since this is a configured feature, you need your config.yaml file
# to include it, otherwise your feature won't be started.

import asyncio, logging
from asyncio.subprocess import PIPE
import os
import json

import entrance
from entrance.feature.cfg_base import ConfiguredFeature

# For production use, this wouldn't require any additional logging.
# But including this here as an example of helping you debug
# your own features. All logs below are gratuitous.
log = logging.getLogger(__name__)


class UserDatabaseFeature(ConfiguredFeature):
    """
    Simple feature to persist a list of users.
    """

    # Feature name, started in config.yml (or by name by the client if it were
    # a dynamic feature instead)
    name = "user_database"

    # Message schema: accept:
    #   store_new_user: args - name, url, languages
    #   get_all_users: no args
    requests = {"store_new_user": ["name", "url", "languages", "year"],
                "get_all_users": []}

    async def do_store_new_user(self, name, url, languages, year):
        log.info("Received store_new_user request[{}, {}, {}, {}]".format(name, url, languages, year))

        if not os.path.exists('users.json'):
            # Create an empty file
            with open('users.json', 'w'): pass

        with open("users.json", "r") as f:
            try:
                users = json.load(f)
                log.info("Loaded: {}".format(users))
            except json.decoder.JSONDecodeError:
                users = []

        users.append({"name": name, "url": url, "languages": languages, "year": year})
        with open("users.json", "w") as f:
            json.dump(users, f, indent=2)

        return self._rpc_success(
            dict(exit_code=0)
        )

    async def do_get_all_users(self):
        log.info("Received get_all_users")
        if not os.path.exists('users.json'):
            users = []
        else:
            with open("users.json", "r") as f:
                try:
                    users = json.load(f)
                    log.info("Loaded: ", users)
                except json.decoder.JSONDecodeError:
                    users = []

        log.info("Sending get_all_users response: {}".format(users))
        return self._rpc_success(users)


# Start up
entrance.main()
