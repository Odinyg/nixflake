#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 1; done

# Launch Polybar on all monitors
if type xrandr >/dev/null 2>&1; then
  while IFS= read -r monitor; do
    MONITOR="$monitor" polybar --reload example &
  done < <(xrandr --query | grep " connected" | cut -d" " -f1)
else
  polybar --reload example &
fi

echo "Polybar launched..."
