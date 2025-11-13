#!/usr/bin/env bash

if [ -n "$1" ]; then
	HOST="$1"
else
	HOST=$(hostname)
fi
export HOST

sudo nixos-rebuild --impure --flake ".#$HOST" switch
