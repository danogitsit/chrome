#!/bin/bash
set -e

# vnc options

export X11VNC_OPTS="${X11VNC_OPTS_OVERRIDE}"

# set sizes for both VNC screen & Chrome window
: ${VNC_SCREEN_SIZE:='1024x768'}
IFS='x' read SCREEN_WIDTH SCREEN_HEIGHT <<< "${VNC_SCREEN_SIZE}"
export VNC_SCREEN="${SCREEN_WIDTH}x${SCREEN_HEIGHT}x24"
export CHROME_WINDOW_SIZE="${SCREEN_WIDTH},${SCREEN_HEIGHT}"

export CHROME_OPTS="${CHROME_OPTS_OVERRIDE}"

exec "$@"
