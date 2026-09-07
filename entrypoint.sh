#!/bin/sh
set -eu

# First boot on an empty Railway volume can leave /home/coder unwritable.
if [ ! -w /home/coder ]; then
  sudo chown -R coder:coder /home/coder
fi

# Official entrypoint runs fixuid then code-server.
# $PORT (set by Railway) overrides the 8080 in --bind-addr.
exec /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:8080 --auth password .
