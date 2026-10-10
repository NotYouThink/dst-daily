# dst-daily

Claims the Don't Starve Together daily gift by launching the game under a
virtual display and closing it again. Runs once a day inside Docker.

## Files
- `Dockerfile` / `entrypoint.sh` / `dontstarve_daily.py` - the image
- `docker-compose.login.yml` - one-time Steam login + game install (VNC)
- `docker-compose.yml` - normal daily mode

## Portainer (stack from git)
1. Stacks > Add stack > Repository. Set the repo URL, reference
   (`refs/heads/main`), and compose path `docker-compose.login.yml`.
   Private repo: enable authentication and use an access token.
2. Environment variables: `VNC_PASSWORD`, `TZ`.
3. Deploy, connect a VNC client to `server:5900`, log into Steam (remember
   password), install Don't Starve Together, then Steam > Exit.
4. Remove that stack, create a new one with compose path `docker-compose.yml`
   and variables `TZ`, `RUN_AT` (optional: `RUN_ON_START`, `POPUP_WAIT`).
5. After pushing changes to git: stack > "Pull and redeploy".

## Manual test run
    docker exec dst-daily /app/entrypoint.sh daily
    docker cp dst-daily:/tmp/dontstarve_popup.png .
