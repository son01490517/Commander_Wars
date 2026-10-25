#!/bin/bash
# Proves that a change still compiles as a normal desktop build (HANDHELD_BUILD=OFF, default options).
# Usage: tools/handheld/build-desktop-check.sh <label>
# Output: .handheld/receipts/<label>/build.log ending with DESKTOP_BUILD_OK on success.
# The build tree lives in the docker volume "cw-build-desktop".
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
LABEL="${1:?usage: $0 <label>}"
OUT="$REPO/.handheld/receipts/$LABEL"
mkdir -p "$OUT"
docker volume create cw-build-desktop >/dev/null
docker run --rm -v "$REPO":/src:ro -v cw-build-desktop:/build cw-linux-arm64 bash -c "
    set -e
    cmake -S /src -B /build -G Ninja -DCMAKE_BUILD_TYPE=Release -DHANDHELD_BUILD=OFF > /build/configure.log 2>&1 \
        || { tail -40 /build/configure.log; exit 1; }
    cmake --build /build -j\$(nproc) 2>&1 | tail -20
    test -x /build/commander_wars
    grep -q 'HANDHELD' /build/CMakeCache.txt && grep 'HANDHELD' /build/CMakeCache.txt || true
    echo DESKTOP_BUILD_OK
" 2>&1 | tee "$OUT/build.log"
grep -q DESKTOP_BUILD_OK "$OUT/build.log"
