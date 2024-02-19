#!/bin/bash

# This script prints all key from a pattern (default to *) on a given redis 

# BE AWARE : KEYS command should not be used on Redis production instances if you have a lot of keys, since it may block the Redis event loop for several seconds.
# Alternative safer method : generate a dump (bgsave), and then parse it and extract the data with the redis python package

rdcli=redis-cli
if [[ -n ${REDIS_PASSWORD} ]]; then
    rdcli="${rdcli} -a ${REDIS_PASSWORD} --no-auth-warning"
fi

# Default to '*' key pattern, meaning all redis keys in the namespace
REDIS_KEY_PATTERN="${REDIS_KEY_PATTERN:-*}"
for key in $(${rdcli} --scan --pattern "$REDIS_KEY_PATTERN")
do
    type=$(${rdcli} type $key)
    #echo "DEBUG ------- type = $type"
    if [[ $type = "list" ]]; then
        printf "$key => \n$(${rdcli} lrange $key 0 -1 | sed 's/^/  /')\n"
    elif [[ $type = "set" ]]; then
        printf "$key => \n$(${rdcli} smembers $key | sed 's/^/  /')\n"
    elif [[ $type = "hash" ]]; then
        printf "$key => \n$(${rdcli} hgetall $key | sed 's/^/  /')\n"
    elif [[ $type = "zset" ]]; then
        printf "$key => \n$(${rdcli} zrange $key 0 -1 withscores | sed 's/^/  /')\n"
    elif [[ $type = "stream" ]]; then
        printf "$key => \n$(${rdcli} xread count -1 streams $key 0 | sed 's/^/  /')\n"
    else
        printf "$key => $(${rdcli} get $key)\n"
    fi
    if [[ $? -ne 0 ]]; then
        echo "DEBUG ------- type = $type"
    fi
done
