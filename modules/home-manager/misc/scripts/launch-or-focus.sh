#!/bin/bash

WINDOW_PATTERN="$1"
LAUNCH_COMMAND="$2"

if [[ -z ${WINDOW_PATTERN:-} || -z ${LAUNCH_COMMAND:-} ]]; then
  printf 'Usage: %s WINDOW_PATTERN LAUNCH_COMMAND\n' "${0##*/}" >&2
  exit 1
fi

focus_window() {
  local address="$1"

  if [[ -n $address ]]; then
    hyprctl dispatch focuswindow "address:$address"
    return 0
  fi

  return 1
}

find_window_address() {
  hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" \
    '.[]|select((.class|test("\\b" + $p + "\\b";"i")) or (.title|test("\\b" + $p + "\\b";"i")))|.address' | head -n1
}

WINDOW_ADDRESS="$(find_window_address)"

if focus_window "$WINDOW_ADDRESS"; then
  exit 0
fi

eval "$LAUNCH_COMMAND" &
sleep 2

WINDOW_ADDRESS="$(find_window_address)"
focus_window "$WINDOW_ADDRESS"
exit 0
