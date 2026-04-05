#!/bin/sh
set -e
cd /app

mix deps.get
mix compile

exec "$@"
