# SSH port forwarding helpers.
# Usage:
#   fip <host> <port1> [port2] ...
#   dip <port1> [port2] ...
#   lip

fip() {
  local host port
  host="$1"
  shift

  for port in "$@"; do
    print "Forwarding port $port to $host"
    ssh -fNL "${port}:localhost:${port}" "${host}"
  done
}

dip() {
  local port

  for port in "$@"; do
    lsof -ti:"${port}" | xargs kill 2>/dev/null || true
    print "Disconnected port $port"
  done
}

lip() {
  ps aux | grep 'ssh -fN' | grep -v grep
}
