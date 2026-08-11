#!/usr/bin/env bash
set -Eeuo pipefail

until mc alias set local http://127.0.0.1:14009 minioautumn minioautumn >/dev/null 2>&1; do
    sleep 1
done

mc mb --ignore-existing local/revolt-uploads

