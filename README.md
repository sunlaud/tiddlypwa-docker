# TiddlyPWA sync server in Docker/Podman

This is a containerized version of the sync server for the glorious [TiddlyPWA](https://tiddly.packett.cool/#), a secure E2E-encrypted Progressive Web App (PWA) version of the brilliant [TiddlyWiki](https://tiddlywiki.com/). [TiddlyPWA adds modern usability & web security features](https://val.packett.cool/blog/tiddlypwa/) to the TiddlyWiki

## Some highligts (or why I did this)
- **Simple Setup**: no need to install yet-another deno/npm/whatewer, just run container
- **Security First**: server code is fetched only at build time or manual reload, preventing supply chain attacks
- **Ephemeral Server**: stateless server container with persistent database storage
- **Rootless**: runs as non-root user inside container + podman is rootless by default

**Note:** whenever `podman` is used, it can be replaced by `docker`, it just happens that I personally favor [Podman](https://podman.io/) much more.

## Quick Start

1. Build the image:
   ```bash
   podman build -t tiddlypwa-sync-server .
   ```

2. Generate admin password hash:
   ```bash
   # With podman-compose
   podman-compose --profile admin-hash run --rm admin-hash-generator
   
   # With podman
   podman run -it --rm tiddlypwa-sync-server hash-admin-password.sh
   ```
   The command will prompt you to enter a password (remember it as 
you will need it to later access admin console).
   Copy entire output into `admin_hash.env`. 
   
   ***Note:** simple shell redirect may not work because of the control chars in the output, producing a 'normal' to the eyes file, which is not readable by deno. Stick with old copy & paste.*

3. Create database directory:
   ```bash
   mkdir tiddly-db
   ```

4. Run the server:
   ```bash
   # With podman-compose
   podman-compose up -d
   
   # With podman (using secrets for admin hash)
   # first create a secret (once)
   podman secret create tiddlypwa_admin_hash ./admin_hash.env
   # run server
   podman run -it --rm -p 8000:8000 --secret tiddlypwa_admin_hash,type=mount -v ./tiddly-db:/app/db:U tiddlypwa-sync-server
   
   # With podman (using regular file mount for admin hash)
   podman run -it --rm -p 8000:8000 -v ./admin_hash.env:/run/secrets/admin_hash -v ./tiddly-db:/app/db:U tiddlypwa-sync-server
   ```

The server will be available at [`http://localhost:8000`](http://localhost:8000).

## Maintenance

### Update Server Code
When you need to update the server code from remote repositories:

```bash
# With podman-compose
podman-compose --profile code-reload run --rm code-reloader

# With podman
podman run -it --rm tiddlypwa-sync-server reload-remote-code.sh
```


# Misc useful stuff

To peek into container: `podman run -it --rm tiddlypwa-sync-server /bin/bash`

To run shell with permissions as inside of rootless container (withing podman user namespace): `podman unshare zsh`


## Deno stuff

To make deno download and cache all dependencies of the script: `deno install --allow-import --entrypoint https://scrip.ts`

To forbid deno run without previously cached deps: `deno run --cached-only https://scrip.ts`