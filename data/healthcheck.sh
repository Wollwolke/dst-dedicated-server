#! /bin/bash

if [ ! "${SHARD_NAME,,}" = "master" ]; then
    # is slave
    dst-ping 127.0.0.1 10999 || exit 1
else
    # is master
    dst-ping 127.0.0.1 11000 || exit 1
fi
