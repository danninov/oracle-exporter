#!/usr/bin/env sh

echo "Generating config"
/usr/bin/confd -onetime -backend env

exec /app -configfile=/oracle.conf -web.listen-address :9161
