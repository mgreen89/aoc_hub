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
    Feature that runs a shell command with zero security
    """

    # Feature name, started in config.yml (or by name by the client if it were
    # a dynamic feature instead)
    name = "user_database"

    # Message schema: accept one request, named 'store_new_user', with one
    # argument, of name 'cmd', and send an RPC reply.
    requests = {"store_new_user": ["name", "url", "languages"],
                "get_all_users": []}

    # do_thing is called whenever a request of name 'thing' is received. So
    # this is the implementation of the 'insecure_shell_cmd' request. This
    # should always return exactly one of:
    #  - self._rpc_success(value)
    #  - self._rpc_failure(err_string).
    async def do_store_new_user(self, name, url, languages):
        log.info("Received store_new_user[{}, {}, {}]".format(name, url, languages))

        if not os.path.exists('users.json'):
            with open('users.json', 'w'): pass

        with open("users.json", "r") as f:
            try:
                users = json.load(f)
                log.info("Loaded: {}".format(users))
            except json.decoder.JSONDecodeError:
                users = {}

        users[name] = {"name": name, "url": url, "languages": languages}
        with open("users.json", "w") as f:
            json.dump(users, f)

        return self._rpc_success(
            dict(exit_code=0)
        )

    async def do_get_all_users(self):
        log.info("Received get_all_users")
        if not os.path.exists('users.json'):
            users = {}
        else:
            with open("users.json", "r") as f:
                try:
                    users = json.load(f)
                    log.info("Loaded: ", users)
                except json.decoder.JSONDecodeError:
                    users = {}
        # Want to return 
        #     { users: "[{"name": "Alice", "url": "some-url", "languages": "C, Python"},
        #                {"name": "Bob", "url": "some-other-url", "languages": "Rust"}]"
        #     }
        json_list = [v for (_, v) in users.items()]
        log.info("Sending {}".format(json.dumps(json_list)))
        return self._rpc_success(json_list)


# Start up
entrance.main()
