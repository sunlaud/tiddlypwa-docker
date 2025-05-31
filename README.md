# TiddlyPWA sync server in Docker/Podman

Original TiddlyPWA: https://tiddly.packett.cool/#


# Launch

Server requires two mounts:
 * admin hash file mounted as `/app/admin_hash`
 * directory for DB mounted as `/app/db` (should be writable by internal `deno` user, the easiest way is to mount with `:U` modifier, though it will change owner on host to mapped user inside container)

*Note:* whenever `podman` is used, it can be replaced by `docker`, it just happens that I personally favor Podman.

To run  server: `podman run -it --rm -p 8000:8000 -v ./admin_hash.env:/app/admin_hash -v ./tiddly-db:/app/db:U tiddlypwa-sync-server`

To run admin password hasher: `podman run -it --rm tiddlypwa-sync-server hash-admin-password.sh`

To reload (update) server code from remove repositories: `podman run -it --rm tiddlypwa-sync-server reload-remote-code.sh`


# Misc useful stuff

To peek into container: `podman run -it --rm tiddlypwa-sync-server /bin/bash`

To build: `podman build -t tiddlypwa-sync-server .`

To run shell with permissions as inside of rootless container (withing podman user namespace): `podman unshare zsh`


## Deno stuff

To make deno download and cache all dependencies of the script: `deno install --allow-import --entrypoint https://scrip.ts`

To forbid deno run without previously cached deps: `deno run --cached-only https://scrip.ts`
