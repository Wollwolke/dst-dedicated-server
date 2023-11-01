#!/bin/bash

# Check volume permissions
if [ ! -w "/data/" ]; then
    echo "Insufficient permissions to create files in /data. Check data volume permissions."
    exit 1
fi

if [ ! -w "/home/dst/dst_server" ]; then
    echo "Insufficient permissions to create files in /home/dst/dst_server. Check dst_server volume permissions."
    exit 1
fi

# Check for game updates before each start. If the game client updates and your server is out of date, you won't be
# able to see it on the server list. If that happens just restart the containers and you should get the latest version

/home/dst/steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +force_install_dir /home/dst/dst_server +login anonymous +app_update 343050 validate +quit

# Check for mandatory env vars
if [ -z ${CLUSTER_NAME+x} ]; then
    echo "Set mandatory ENV variable CLUSTER_NAME"
    exit 1
fi
if [ -z ${SHARD_NAME+x} ]; then
    echo "Set mandatory ENV variable SHARD_NAME"
    exit 1
fi

mkdir -p "/data/$CLUSTER_NAME/"

# Set cluster_token
if [ ! -z ${CLUSTER_TOKEN+x} ]; then
    echo $CLUSTER_TOKEN > "/data/$CLUSTER_NAME/cluster_token.txt"
else
    if [ ! -f "/data/$CLUSTER_NAME/cluster_token.txt" ]; then
        echo "No cluster_token set or found"
        exit 1
    fi
fi

# Cluster config
if [ "${SHARD_NAME,,}" = "master" ]; then
    # Check for existing cluster.ini
    if [ ! -f "/data/$CLUSTER_NAME/cluster.ini" ]; then
        cp "$HOME/data/cluster_default.ini" "/data/$CLUSTER_NAME/cluster.ini"
        echo "No cluster.ini for $CLUSTER_NAME found - using default config"
    fi

    if [ -z ${KEEP_CLUSTER_CONFIG+x} ]; then
        # replace config values with env vars
        echo "Overwriting cluster config with ENV variables"
        if [ ! -z ${GAME_MODE+x} ]; then
            sed -i "/^game_mode =/cgame_mode = $GAME_MODE" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${MAX_PLAYERS+x} ]; then
            sed -i "/^max_players =/cmax_players = $MAX_PLAYERS" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${PVP+x} ]; then
            sed -i "/^pvp =/cpvp = $PVP" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${PAUSE_WHEN_EMPTY+x} ]; then
            sed -i "/^pause_when_empty =/cpause_when_empty = $PAUSE_WHEN_EMPTY" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${CLUSTER_INTENTION+x} ]; then
            sed -i "/^cluster_intention =/ccluster_intention = $CLUSTER_INTENTION" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${CLUSTER_NAME+x} ]; then
            sed -i "/^cluster_name =/ccluster_name = $CLUSTER_NAME" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${CLUSTER_DESCRIPTION+x} ]; then
            sed -i "/^cluster_description =/ccluster_description = $CLUSTER_DESCRIPTION" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${CLUSTER_PW+x} ]; then
            sed -i "/^cluster_password =/ccluster_password = $CLUSTER_PW" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${STEAM_GROUP_ID+x} ]; then
            sed -i "/^steam_group_id =/csteam_group_id = $STEAM_GROUP_ID" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${STEAM_GROUP_ONLY+x} ]; then
            sed -i "/^steam_group_only = /csteam_group_only = $STEAM_GROUP_ONLY" "/data/$CLUSTER_NAME/cluster.ini"
        fi
        if [ ! -z ${STEAM_GROUP_ADMINS+x} ]; then
            sed -i "/^steam_group_admins =/csteam_group_admins = $STEAM_GROUP_ADMINS" "/data/$CLUSTER_NAME/cluster.ini"
        fi
    fi
fi

# Add gameserver admins
if [ ! -z ${GAME_ADMINS+x} ]; then
    > "/data/$CLUSTER_NAME/adminlist.txt"
    IFS=',' read -ra ADMINS <<< "$GAME_ADMINS"
    for i in "${ADMINS[@]}"; do
        echo "$i" >> "/data/$CLUSTER_NAME/adminlist.txt"
    done
fi

# Shard config
mkdir -p "/data/$CLUSTER_NAME/$SHARD_NAME/"
cp "$HOME/data/server.ini" "/data/$CLUSTER_NAME/$SHARD_NAME/server.ini"

if [ ! "${SHARD_NAME,,}" = "master" ]; then
    # is slave
    sed -i "s/server_port = 11000/server_port = 10999/" "/data/$CLUSTER_NAME/$SHARD_NAME/server.ini"
    sed -i "s/is_master = true/is_master = false/" "/data/$CLUSTER_NAME/$SHARD_NAME/server.ini"
    sed -i "s/name = Master/name = $SHARD_NAME/" "/data/$CLUSTER_NAME/$SHARD_NAME/server.ini"
fi

# Mod Config
if [ ! -z ${MOD_COLLECTION+x} ]; then
    echo "ServerModCollectionSetup(\"$MOD_COLLECTION\")" > "$HOME/dst_server/mods/dedicated_server_mods_setup.lua"
fi

cd $HOME/dst_server/bin
exec ./dontstarve_dedicated_server_nullrenderer -cluster "$CLUSTER_NAME" -shard "$SHARD_NAME" -persistent_storage_root "/data" -conf_dir "."
