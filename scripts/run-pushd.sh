#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${ENABLE_PUSHD:-0}" != "1" ]]; then
    exec sleep infinity
fi

exec /home/container/scripts/wait-and-run.sh /home/container/source/target/debug/revolt-pushd

