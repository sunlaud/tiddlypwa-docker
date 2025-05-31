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
set -eu
if [ ! -f "$ADMIN_HASH_FILE" ] || [ ! -s "$ADMIN_HASH_FILE" ]; then
    echo "Error: admin hash&salt file does not exist or is empty. Generate admin hash and salt by running 'podman run -it --rm tiddlypwa-sync-server /app/hash-admin-password.sh', put it in file and mount at path $ADMIN_HASH_FILE"
    exit 1
fi
if [ ! -d "$DB_DIR" ] || [ ! -w "$DB_DIR" ]; then
  echo "Database directory does not exist or is not writable: $DB_DIR. Mount a directory inside container and make  it writable to deno user by adding flag: '-v ./some-db-dir-on-host:/app/db:U'"
  exit 1
fi
#-cached-only allows running only cached (i.e. previously installed files); --lock and --frozen allow to run exactly same dependencies as installed
exec deno run --lock --frozen --cached-only --unstable-broadcast-channel --allow-env --allow-read="$DB_DIR" --allow-write="$DB_DIR" --env-file="$ADMIN_HASH_FILE" --allow-net=:8000 "$SERVER_SCRIPT_URL"
EOF

COPY --chmod=555 <<-EOF hash-admin-password.sh
#!/bin/sh
set -eu
deno run --cached-only "$HASHER_SCRIPT_URL"
EOF

COPY --chmod=555 <<-EOF reload-remote-code.sh
#!/bin/sh
set -eu
rm -f /app/deno.lock
deno install --allow-import --reload --lock --entrypoint "$SERVER_SCRIPT_URL"
deno install --allow-import --reload --lock --entrypoint "$HASHER_SCRIPT_URL"
EOF


RUN chown deno:deno /app

USER deno

RUN /app/reload-remote-code.sh

CMD ["/app/tiddlypwa-sync-server.sh"]

