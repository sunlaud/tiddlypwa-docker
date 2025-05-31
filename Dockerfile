# Original TiddlyPWA: https://tiddly.packett.cool/#
# requires two mounts: admin hash file and a directory for DB (should be writable by internal 'deno' user, the easiest way is to mount with :U modifier)
# to run  server: `podman run -it --rm -p 8000:8000 -v ./admin_hash.env:/app/admin_hash -v ./tiddly-db:/app/db:U tiddlypwa-sync-server`
# to run admin password hasher: `podman run -it --rm tiddlypwa-sync-server hash-admin-password.sh`
# to peek into container: `podman run -it --rm tiddlypwa-sync-server /bin/bash`
# built with: `podman build -t tiddlypwa-sync-server .`
# to run shell with permissions as inside of rootless container (withing podman user namespace): podman unshare zsh
# to make deno download and cache all dependencies of the script: `deno install --allow-import --entrypoint https://scrip.ts`
# to forbid deno run without previously cached deps: `deno run --cached-only https://scrip.ts`

FROM docker.io/denoland/deno:latest

ARG SERVER_SCRIPT_URL="https://codeberg.org/valpackett/tiddlypwa/raw/branch/release/server/run.ts"
ARG HASHER_SCRIPT_URL="https://codeberg.org/valpackett/tiddlypwa/raw/branch/release/server/hash-admin-password.ts"
ARG DB_DIR=/app/db
ARG ADMIN_HASH_FILE=/app/admin_hash
ENV DB_PATH=$DB_DIR/tiddlypwa.db
EXPOSE 8000
WORKDIR /app

COPY --chmod=555 <<-EOF tiddlypwa-sync-server.sh
#!/bin/sh
if [ ! -f "$ADMIN_HASH_FILE" ] || [ ! -s "$ADMIN_HASH_FILE" ]; then
    echo "Error: admin hash&salt file does not exist or is empty. Generate admin hash and salt by running 'podman run -it --rm tiddlypwa-sync-server /app/hash-admin-password.sh', put it in file and mount at path $ADMIN_HASH_FILE"
    exit 1
fi
if [ ! -d "$DB_DIR" ] || [ ! -w "$DB_DIR" ]; then
  echo "Database directory does not exist or is not writable: $DB_DIR. Mount a directory inside container and make  it writable to deno user by adding flag: '-v ./some-db-dir-on-host:/app/db:U'"
  exit 1
fi
#--cached-only allows running only cached (i.e. previously installed files)
exec deno run --cached-only --unstable-broadcast-channel --allow-env --allow-read="$DB_DIR" --allow-write="$DB_DIR" --env-file="$ADMIN_HASH_FILE" --allow-net=:8000 "$SERVER_SCRIPT_URL"
EOF

COPY --chmod=555 <<-EOF hash-admin-password.sh
#!/bin/sh
deno run --cached-only "$HASHER_SCRIPT_URL"
EOF

USER deno

RUN <<-EOF
set -eu
#install/cache files so that we can later run cached-only
deno install --allow-import --entrypoint "$SERVER_SCRIPT_URL"
deno install --allow-import --entrypoint "$HASHER_SCRIPT_URL"
EOF

CMD ["/app/tiddlypwa-sync-server.sh"]

