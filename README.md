# Don't Starve Together - Dedicated Server Running on Docker

[![Docker Buils Status](https://github.com/Wollwolke/dst-dedicated-server/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Wollwolke/dst-dedicated-server/actions/workflows/docker-publish.yml)
[![License: GPL-3.0](https://img.shields.io/github/license/wollwolke/dst-dedicated-server?label=License)](https://github.com/Wollwolke/dst-dedicated-server/blob/master/LICENSE)


The objective of this project is to create a easily configurable DST server for two shards (e.g. Forest + Caves) without having to download the server binary for each shard.  
The docker image does not include the DST server, the latest one is downloaded and stored in a docker volume on first launch.

**Features:**

- Support for two shards (Forest + Caves)
- Built-in docker [health check](https://github.com/Wollwolke/dst-ping) for server monitoring
- Game server console available using `docker attach`

## Requirements

- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Minimal Setup

Steps to get a server up & running with the default settings.

1. Copy the provided [`docker-compose.yml`](docker-compose.yml) to your system
2. Replace the `CLUSTER_TOKEN` ([How to get a cluster token](doc/guides.md#acquire-cluster-token))
3. Update the volume path to store the configuration / world files *for all shards* (`/path/to/dst_data`)
4. Run:

``` sh
docker-compose up -d
```

>ℹ If the server does not appear in the server browser, make sure that the game and server are up to date.
Depending on the number of mods, the server may take a few minutes to start.

## Configuration

The key configuration options can be modified via environment variables in the compose file.
All options are shown in the following table.  
Just add the options to the corresponding `environment` section of the shard.

| Option              | Shard  | Notes                                                             |
|---------------------|--------|-------------------------------------------------------------------|
| CLUSTER_DESCRIPTION | Master | This will show up in the server details in the server browser. |
| CLUSTER_INTENTION   | Master | The server's playstyle (`cooperative` / `competitive` / `social` / `madness`). |
| CLUSTER_NAME        | All    | **Mandatory, needs to be identical for all shards** - Server name. |
| CLUSTER_PW          | Master | This is the password that players must enter to join your server. Leave this blank for no password. |
| CLUSTER_TOKEN       | Master | **Mandatory** - Cluster token for the server. |
| GAME_ADMINS         | Master | Comma-separated list of Klei-IDs ([How to get your Kleid-ID](doc/guides.md#acquire-cluster-token)) |
| GAME_MODE           | Master | The server's game mode (`survival` / `endless` / `wilderness`). |
| KEEP_CLUSTER_CONFIG | Master | Set this to prevent overwriting a manually edited `cluster.ini` file. |
| MAX_PLAYERS         | Master | The maximum number of players that may be connected to the cluster at one time. |
| MOD_COLLECTION      | All    | Steam ID of a workshop collection with mods to install. |
| PAUSE_WHEN_EMPTY    | Master | `true` pauses the server when there are no players connected. |
| PVP                 | Master | `true` enables PVP |
| SHARD_NAME          | Both   | **Mandatory** - The first one is `Master`. Others can be freely chosen. |
| STEAM_GROUP_ADMINS  | Master | When this is set to `true`, admins of the configured steam group will also have admin status on the server. |
| STEAM_GROUP_ID      | Master | Steam group id for STEAM_GROUP_ADMINS / STEAM_GROUP_ONLY settings |
| STEAM_GROUP_ONLY    | Master | When set to `true`, the server will only allow connections from players belonging to the configured steam group. |

### Manual Configuration

All configuration files are stored in the volume mapped to `/data` next to the world files.  
To prevent the container start script to overwrite manual changes to the `cluster.ini` file, make sure to remove the respective option from the compose file or set the `KEEP_CLUSTER_CONFIG` option.

## World Generation

To customize the world generation a `leveldataoverride.lua` file is required for every shard.

The required configuration files can be created by setting up a server in the game.
The files can be found in:

- Unix: `~/.klei/DoNotStarveTogether/Cluster_X/<shard_name>/leveldataoverride.lua`
- Windows: `C:\Users\<username>\Documents\Klei\DoNotStarveTogether\Cluster_X\<shard_name>\leveldataoverride.lua`

Copy the files to the docker mount created [above](#minimal-setup) and regenerate the world.

**Regenerate world in-game:**

- Start the game and connect to the server
- Open the console (by pressing `~`) and switch to `Remote` by pressing `Crtl`:
- Enter:

```
c_regenerateworld()
```

**Regenerate world using the terminal:**

- Attach to the game server console: `docker attach dst_master`
- Enter:

```
c_regenerateworld()
```

- Detach from the console: `Ctrl`+`P`, `Ctrl`+`Q`

> ℹ To create the directory structure within the Docker mount, start the servers at least once.

## Modding

To install mods create a steam workshop collection and copy the ID (shown in URL bar) to the `MOD_COLLECTION` option of the compose file.

> ℹ The `MOD_COLLECTION` option must be set for all shards.

The simplest method to activate the installed mods is to configure them within the game.
Launching a server with enabled mods through the game generates `modoverrides.lua` files in:

- Unix: `~/.klei/DoNotStarveTogether/Cluster_X/<shard_name>/modoverrides.lua`
- Windows: `C:\Users\<username>\Documents\Klei\DoNotStarveTogether\Cluster_X\<shard_name>\modoverrides.lua`

Copy the files to the docker mount created [above](#minimal-setup) and restart the containers.

> ℹ To create the directory structure within the Docker mount, start the servers at least once.

## Updates

The server files and installed mods are automatically updated upon every container start.
