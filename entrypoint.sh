#!/bin/bash
# Modes:  cron (default, runs at the time(s) in $RUN_AT) | daily (run once) | login (VNC for first-time setup)
export DISPLAY=:99

start_display() {
  rm -f /tmp/.X99-lock
  Xvfb :99 -screen 0 1280x720x24 -nolisten tcp &
  XVFB_PID=$!
  sleep 2
  openbox &
  WM_PID=$!
}

stop_display() {
  kill "$WM_PID" "$XVFB_PID" 2>/dev/null || true
}

run_daily() {
  echo "[$(date)] Starting daily run"
  start_display
  python3 /app/dontstarve_daily.py
  stop_display
  echo "[$(date)] Daily run finished"
}

case "${1:-cron}" in
  login)
    if [ -z "$VNC_PASSWORD" ]; then
      echo "Set VNC_PASSWORD to use login mode"; exit 1
    fi
    start_display
    x11vnc -display :99 -forever -passwd "$VNC_PASSWORD" -rfbport 5900 -quiet &
    echo "VNC is up on port 5900. Log into Steam, install Don't Starve Together,"
    echo "then use Steam > Exit and stop the container."
    steam $STEAM_EXTRA_ARGS
    ;;
  daily)
    run_daily
    ;;
  cron)
    # RUN_AT can hold several times, comma-separated: RUN_AT=09:00,21:00
    for t in ${RUN_AT//,/ }; do
      if ! [[ "$t" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        echo "Invalid time in RUN_AT: '$t' (use HH:MM, e.g. 09:00 or 09:00,21:00)"; exit 1
      fi
    done
    [ "$RUN_ON_START" = "true" ] && run_daily
    while true; do
      now=$(date +%s)
      next=""
      for t in ${RUN_AT//,/ }; do
        ts=$(date -d "today $t" +%s)
        [ "$ts" -le "$now" ] && ts=$(date -d "tomorrow $t" +%s)
        if [ -z "$next" ] || [ "$ts" -lt "$next" ]; then next=$ts; fi
      done
      echo "[$(date)] Next run at $(date -d @$next)"
      sleep $((next - now))
      run_daily
    done
    ;;
  *)
    exec "$@"
    ;;
esac
