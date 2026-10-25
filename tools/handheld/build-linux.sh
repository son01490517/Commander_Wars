#!/bin/bash
# Builds the game for Linux arm64 inside Docker (phase 1A measurement build).
# Usage: tools/handheld/build-linux.sh [extra cmake args...]
# The build tree lives in the docker volume "cw-build"; the source is mounted read-only.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE=cw-linux-arm64

if ! docker image inspect "$IMAGE" >/dev/null 2>&1 || [ "${REBUILD_IMAGE:-0}" = "1" ]; then
    docker build -t "$IMAGE" -f "$REPO/tools/handheld/docker/Dockerfile.measure" "$REPO/tools/handheld/docker"
fi
docker volume create cw-build >/dev/null

docker run --rm -v "$REPO":/src:ro -v cw-build:/build "$IMAGE" bash -c "
    set -e
    cmake -S /src -B /build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DDEPLOY_RESOURCES_AS_FOLDER=ON -DDEFAULTAIPIPE=OFF $* > /build/configure.log 2>&1 \
        || { tail -40 /build/configure.log; exit 1; }
    cmake --build /build -j\$(nproc) 2>&1 | tail -20
    test -x /build/commander_wars
    echo BUILD_OK
"
