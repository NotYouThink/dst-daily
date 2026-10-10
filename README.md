> **Made with AI.** This project, including the code, the Docker setup and this guide, was written with the help of an AI assistant and then tested by a human. It works on the author's server, but it has not been tested on every system.

# dst-daily

Automatically claims the Don't Starve Together daily gift. 
Once a day a Docker container starts Steam on a hidden virtual screen, launches the game, waits for the main menu popup to appear, and closes everything again.

---

## Contents

1. [How it works](#how-it-works)
2. [What you need](#what-you-need)
3. [Step 1: Get the files into your own repository](#step-1-get-the-files-into-your-own-repository)
4. [Step 2: One-time Steam login](#step-2-one-time-steam-login)
5. [Step 3: Switch to daily mode](#step-3-switch-to-daily-mode)
6. [Step 4: Test it](#step-4-test-it)
7. [Settings](#settings)
8. [Updating](#updating)
9. [Troubleshooting](#troubleshooting)
10. [Warnings](#warnings)
11. [Uninstall](#uninstall)

---

## How it works

You deploy two Portainer stacks from the same repository, one after the
other. Both share one Docker volume that stores your Steam login and the game.

| Stack | Compose file | Purpose | How long you keep it |
|---|---|---|---|
| `dst-login` | `docker-compose.login.yml` | Opens Steam with a remote desktop (VNC) so you can log in and install the game | Only for the first setup |
| `dst-daily` | `docker-compose.yml` | Runs the daily claim automatically | Permanently |

Inside the container, `entrypoint.sh` waits until your chosen time, starts a
virtual screen, and runs `dontstarve_daily.py`, which launches the game and
closes it again.

## What you need

- A server with Docker and Portainer installed and working
- A Steam account that owns Don't Starve Together
- A VNC client on your own PC for the one-time login, for example
  [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) 
## Step 1: One-time Steam login

### 1.1 Create the login stack in Portainer

1. In Portainer, open your environment, then Stacks → Add stack.
2. **Name:** `dst-login`
3. **Build method:** choose Repository.
4. **Repository URL:** `https://github.com/NotYouThink/dst-daily.git`
5. **Repository reference:** `refs/heads/main`
6. **Compose path:** `docker-compose.login.yml`
7. Leave Authentication switched off (it's only needed for private repositories).
8. Under Environment variables, click Add environment variable twice:
    
    |Name|Value|
    |---|---|
    |`VNC_PASSWORD`|A password you choose|
    |`TZ`|Your timezone, e.g. `Europe/Berlin` or `America/New_York` ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))|
    
1. Click **Deploy the stack**.

### 1.2 Connect with VNC

1. Open your VNC client and connect to `YOUR-SERVER-IP:5900`.
2. Enter the `VNC_PASSWORD` you chose.
### 1.3 Log in and install the game

1. Log in with your Steam account.
2. Open your Library and Install on't Starve Together.
3. Close Steam properly: in Steam's top-left menu choose Steam → Exit.

> The last point matters. Steam writes the saved login to disk when it exits cleanly. If you just stop the container, you may have to log in again.

## Step 2: Switch to daily mode

1. In Portainer go to Stacks, open `dst-login`, and remove it.
2. Add a new stack: Stacks → Add stack.
3. **Name:** `dst-daily`
4. **Build method:** Repository, with the same URL and reference as before.
5. **Compose path:** `docker-compose.yml`
6. **Environment variables:**
    
    |Name|Value|
    |---|---|
    |`TZ`|Your timezone, e.g. `Europe/Berlin` or `America/New_York` ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))|
    |`RUN_AT`|The time of the daily run in 24-hour format, e.g. `09:00`|
    
7. Deploy the stack.

Since the image was already built in Step 1, this deploys quickly. The container now waits until `RUN_AT` each day, claims the gift, and goes back to sleep.
## Step 3: Test it

Don't wait until tomorrow. Run it once by hand.

**Option A: with SSH** on your server:

bash

```bash
docker exec dst-daily /app/entrypoint.sh daily
```
### Check the screenshot
Every run saves a screenshot of the screen just before the game is closed. Copy it out of the container:

bash

```bash
docker cp dst-daily:/tmp/dontstarve_popup.png .
```

Open the picture. You're looking for the Don't Starve Together main menu (with the daily gift popup, if it hasn't been claimed yet that day).

| What the picture shows                 | Meaning                                  |
| -------------------------------------- | ---------------------------------------- |
| Main menu / gift popup                 | It works.                                |
| Loading screen or Steam still starting | Increase `POPUP_WAIT`.                   |
| Steam login window                     | The login wasn't saved. Repeat Step 1.   |

The screenshot is overwritten on every run and is deleted if the container is recreated, for example when you redeploy the stack.

Finally, check in the game itself on the following day that you received your daily item.
## Settings

Set these as **Environment variables** in the Portainer stack.

|Variable|Default|Meaning|
|---|---|---|
|`TZ`|`UTC`|Timezone used for `RUN_AT` and the log timestamps|
|`RUN_AT`|`09:00`|Daily run time, 24-hour format `HH:MM`|
|`RUN_ON_START`|`false`|If `true`, also runs once whenever the container starts|
|`POPUP_WAIT`|`60`|Seconds to wait for the main menu before closing the game. Increase on slow servers.|
|`VNC_PASSWORD`|none|Only for the login stack: password for the remote desktop|

After changing a variable, use **Update the stack** (or **Pull and redeploy**) in Portainer.
## Troubleshooting

### The screenshot is black or shows a loading screen

1. Raise `POPUP_WAIT` to `90` or `120`.
2. While a test run is active, check whether the game process exists:
bash

```bash
   docker exec dst-daily pgrep -af dontstarve_steam
```

If a line is printed, the game started. If nothing is printed, Steam never launched the game. In that case look at the Steam logs inside the container under `/home/steam/.local/share/Steam/logs/`.

### Steam asks me to log in again

Steam sessions can expire or be invalidated, for example when you change your password or log in from many places. Redo [Step 1](#step-1-one-time-steam-login) using the same volume. Your downloaded game files are kept.

### Another device is kicking my session

Steam allows only **one active game session per account**. Don't play on another PC with the same account during the time the container runs the game (about 1 to 2 minutes a day).
## Warnings

- **Use at your own risk.** This automates launching a game on your own Steam account. It does not interact with the game's network traffic or cheat in any way, but you're responsible for staying within Steam's and Klei's terms.
- **Security trade-off.** The container runs with seccomp and AppArmor disabled, which weakens its isolation. That's acceptable for a single-purpose container on a private server, but don't reuse these settings for services exposed to the internet.
- **Keep VNC private.** Port 5900 is only used by the login stack. Never expose it to the internet and remove the login stack when setup is done.
- **Your Steam login lives in the Docker volume** `dst-steam-home`. Anyone with access to your server's Docker volumes can use it, so protect your server accordingly. Treat the volume like a saved password.
- **No guarantees.** Game updates, Steam updates, or changes to the daily gift system can break the script at any time.

## Uninstall

1. In Portainer, remove the `dst-daily` stack (and `dst-login` if it still exists).
2. Under **Volumes**, delete `dst-steam-home` to remove the saved login and the game files.
3. Under **Images**, delete `dst-daily` to free the disk space of the image.
4. Optionally, deauthorize the device in your Steam account settings (Steam → Settings → Security).