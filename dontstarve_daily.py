#!/usr/bin/env python3
"""
Claim the Don't Starve Together daily gift on Linux.

The gift is granted as soon as the popup shows on the main menu, so the script
only needs to launch the game, wait, and close it again. No clicking required.

On a desktop (e.g. Linux Mint):
    python3 dontstarve_daily.py

On a headless server (virtual display):
    xvfb-run -a -s "-screen 0 1280x720x24" python3 dontstarve_daily.py

Requirements:
    Steam installed and logged in once with "remember password",
    Don't Starve Together installed.
    Headless only:  sudo apt install xvfb
    Optional debug screenshot:  sudo apt install scrot
"""

import logging
import os
import shutil
import subprocess
import sys
import time

# ---------------------------------------------------------------- config ----
APP_ID = "322330"  # Don't Starve Together on Steam

# For the Flatpak version of Steam use:
#   STEAM_CMD = ["flatpak", "run", "com.valvesoftware.Steam", "-silent"]
#   STEAM_SHUTDOWN = ["flatpak", "kill", "com.valvesoftware.Steam"]
STEAM_CMD = ["steam", "-silent"] + os.environ.get("STEAM_EXTRA_ARGS", "").split()
STEAM_SHUTDOWN = ["steam", "-shutdown"]

GAME_PROCESS_PATTERN = "dontstarve_steam"  # game binary; must not match this script's own name

# Seconds to wait for Steam login + game start + main menu popup.
# Increase this on slow machines.
POPUP_WAIT = int(os.environ.get("POPUP_WAIT", "45"))

SCREENSHOT_PATH = "/tmp/dontstarve_popup.png"
FOLLOWUP_SCRIPT = os.environ.get("FOLLOWUP_SCRIPT")  # optional
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    stream=sys.stdout,
)
log = logging.getLogger("dontstarve-daily")


def start_game():
    log.info("Launching Don't Starve Together (app %s) via Steam", APP_ID)
    subprocess.Popen(
        STEAM_CMD + ["-applaunch", APP_ID],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def take_screenshot():
    """Save a screenshot so you can check the popup actually appeared."""
    if shutil.which("scrot"):
        subprocess.run(["scrot", "-o", SCREENSHOT_PATH], check=False)
        log.info("Saved screenshot to %s", SCREENSHOT_PATH)


def stop_game():
    log.info("Closing game and Steam")
    subprocess.run(["pkill", "-f", GAME_PROCESS_PATTERN], check=False)
    time.sleep(2)
    subprocess.run(STEAM_SHUTDOWN, check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    if not os.environ.get("DISPLAY"):
        sys.exit("No DISPLAY set. Run via: xvfb-run -a python3 " + sys.argv[0])

    try:
        start_game()
        log.info("Waiting %ss for the main menu popup", POPUP_WAIT)
        time.sleep(POPUP_WAIT)
        take_screenshot()
    finally:
        stop_game()

    if FOLLOWUP_SCRIPT:
        log.info("Running follow-up script: %s", FOLLOWUP_SCRIPT)
        subprocess.run([sys.executable, FOLLOWUP_SCRIPT], check=False)


if __name__ == "__main__":
    main()
