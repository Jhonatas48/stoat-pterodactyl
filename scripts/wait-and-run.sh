#!/usr/bin/env bash
set -Eeuo pipefail

for endpoint in 127.0.0.1:27017 127.0.0.1:6379 127.0.0.1:5672 127.0.0.1:14009; do
    host="${endpoint%:*}"
    port="${endpoint##*:}"
    until nc -z "$host" "$port"; do
        sleep 1
    done
done

exec "$@"

