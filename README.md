# TiddlyPWA sync server in Docker/Podman

This is a containerized version of the glorious [TiddlyPWA](https://tiddly.packett.cool/#) sync server, which provides synchronization capabilities for TiddlyWiki instances. It allows multiple users to collaborate on the same TiddlyWiki by syncing changes through a central server.

Original TiddlyPWA project: https://tiddly.packett.cool/#
Upstream server code: https://codeberg.org/valpackett/tiddlypwa


# Docker/Podman commands

*Note:* whenever `podman` is used, it can be replaced by `docker`, it just happens that I personally favor Podman.

To build image: `podman build -t tiddlypwa-sync-server .`

Running server requires two mounts:
 * admin hash file mounted as `/run/secrets/admin_hash`
 * directory for DB mounted as `/app/db` (should be writable by internal `deno` user, the easiest way is to mount with `:U` modifier, though it will change owner on host to mapped user inside container)

Prerequisite: a directory for wikis DB on host: `mkdir tiddly-db`.

To run server with with admin hash as secret: `podman run -it --rm -p 8000:8000 --secret tiddlypwa_admin_hash,type=mount -v ./tiddly-db:/app/db:U tiddlypwa-sync-server`

Before running you should create a secret: `podman secret create tiddlypwa_admin_hash ./admin_hash.env`

To run admin password hasher: `podman run -it --rm tiddlypwa-sync-server hash-admin-password.sh`

To reload (update) server code from remote repositories: `podman run -it --rm tiddlypwa-sync-server reload-remote-code.sh`


# Docker Compose Setup

The project includes a `docker-compose.yml` file for easier management. Here's how to use it:

1. Create the database directory: `mkdir tiddly-db`

2. Generate admin password hash: `podman-compose run --rm admin-hash-generator`
   The command will prompt you to enter a password. After entering it, it will output a hash.
   Copy the entire output and paste it into a new file named `admin_hash.env`.

3. Start the main service: `podman-compose up -d tiddlypwa-sync-server`

4. When you need to update the code from remote repositories: `podman-compose run --rm code-reloader`

The server will be available at `http://localhost:8000`.


# Misc useful stuff

To peek into container: `podman run -it --rm tiddlypwa-sync-server /bin/bash`

To run shell with permissions as inside of rootless container (withing podman user namespace): `podman unshare zsh`


## Deno stuff

To make deno download and cache all dependencies of the script: `deno install --allow-import --entrypoint https://scrip.ts`

To forbid deno run without previously cached deps: `deno run --cached-only https://scrip.ts`