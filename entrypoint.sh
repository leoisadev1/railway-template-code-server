#!/bin/sh
set -eu

if [ -z "${PASSWORD:-}" ] && [ -z "${HASHED_PASSWORD:-}" ]; then
  echo "PASSWORD or HASHED_PASSWORD is required; refusing a stored or generated fallback password." >&2
  exit 1
fi

PORT="${PORT:-8080}"
case "$PORT" in
  ''|*[!0-9]*) echo "PORT must be an integer between 1 and 65535." >&2; exit 1 ;;
esac
if [ "${#PORT}" -gt 5 ] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "PORT must be an integer between 1 and 65535." >&2
  exit 1
fi
export PORT HOME=/home/coder USER=coder LOGNAME=coder

if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$HOME"
  # Railway mounts new volumes as root; preserve existing user-owned files.
  find "$HOME" -xdev -uid 0 -exec chown -h coder:coder {} +
  chown coder:coder "$HOME"
  chmod u+rwx "$HOME"
  cd "$HOME"
  exec setpriv --reuid=coder --regid=coder --init-groups \
    /usr/bin/entrypoint.sh --bind-addr "0.0.0.0:${PORT}" --auth password .
fi

if [ "$(id -un)" != coder ] || [ ! -w "$HOME" ]; then
  echo "Start as root to initialize the volume, or as coder with a writable /home/coder." >&2
  exit 1
fi
cd "$HOME"
exec /usr/bin/entrypoint.sh --bind-addr "0.0.0.0:${PORT}" --auth password .
