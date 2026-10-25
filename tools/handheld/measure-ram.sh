#!/bin/bash
# Measures RAM of the Linux arm64 build (from build-linux.sh) during an automated
# 2-player AI-vs-AI match at 640x480, rendered by Mesa llvmpipe under Xvfb.
# llvmpipe keeps textures in process memory, which approximates the unified
# memory of the RG35XX (Mali-G31), so RSS includes texture memory.
#
# Usage: tools/handheld/measure-ram.sh [-l label] [-s seconds] [-m maps/2_player/File.map] [-M] [-j init.js] [-e KEY=VALUE]...
#   -M  stay in the main menu (no match); useful for main-menu screenshots and idle RAM
#   -j  use another automation script (repo-relative path) instead of tools/handheld/ramtest/init.js
#   -e  extra environment variable for the game process (repeatable); files the game writes to /out land in the receipt folder
# Output: .handheld/receipts/<label>/{summary.json,ram.csv,game.log,shot.png}
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
LABEL="ram-$(date +%Y%m%d-%H%M%S)"
SECONDS_TO_RUN=360
MAP="maps/2_player/Agitated.map"
MENU_ONLY=0
INIT_JS="tools/handheld/ramtest/init.js"
EXTRA_ENV=()
while getopts "l:s:m:Mj:e:" opt; do
    case $opt in
        l) LABEL="$OPTARG" ;;
        s) SECONDS_TO_RUN="$OPTARG" ;;
        m) MAP="$OPTARG" ;;
        M) MENU_ONLY=1 ;;
        j) INIT_JS="$OPTARG" ;;
        e) EXTRA_ENV+=(-e "$OPTARG") ;;
        *) echo "usage: $0 [-l label] [-s seconds] [-m map] [-M] [-j init.js]"; exit 1 ;;
    esac
done
OUT="$REPO/.handheld/receipts/$LABEL"
mkdir -p "$OUT"
MAP_FOLDER="$(dirname "$MAP")/"
MAP_FILE="$(basename "$MAP")"

docker run --rm -v "$REPO":/src:ro -v cw-build:/build:ro -v "$OUT":/out \
    -e SECONDS_TO_RUN="$SECONDS_TO_RUN" -e MAP_FOLDER="$MAP_FOLDER" -e MAP_FILE="$MAP_FILE" -e MENU_ONLY="$MENU_ONLY" -e INIT_JS="$INIT_JS" ${EXTRA_ENV[@]+"${EXTRA_ENV[@]}"} \
    -e GIT_REV="$(git -C "$REPO" rev-parse --short HEAD)$(git -C "$REPO" diff --quiet || echo -dirty)" \
    cw-linux-arm64 bash -c '
set -u
printf "pcm.!default { type null }\nctl.!default { type hw card 0 }\n" > /etc/asound.conf
Xvfb :1 -screen 0 640x480x24 >/dev/null 2>&1 &
sleep 2
export DISPLAY=:1 LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb LANG=C.UTF-8
U=/tmp/user/
mkdir -p $U
sed -e "s#RAMTEST_MAP_FOLDER#$MAP_FOLDER#" -e "s#RAMTEST_MAP_FILE#$MAP_FILE#" /src/$INIT_JS > $U/init.js
[ "$MENU_ONLY" = 1 ] && sed -i "/enterSingleplayer/d" $U/init.js
cat > $U/Commander_Wars.ini <<EOF
[%General]
UserPath=$U
AutomaticUpdates=false
[Resolution]
width=640
height=480
fullscreen=false
borderless=false
EOF
cd /src
/build/commander_wars --userPath $U --debugLevel 0 > /tmp/game.log 2>&1 &
PID=$!
echo "t_s,rss_kb,rss_anon_kb,rss_file_kb,phase" > /out/ram.csv
MENU_KB=0; START_KB=0; PHASE=loading; T=0
while [ $T -lt $SECONDS_TO_RUN ]; do
    sleep 5; T=$((T+5))
    kill -0 $PID 2>/dev/null || { PHASE=exited; break; }
    grep -q "RAMTEST: main menu" /tmp/game.log && [ $PHASE = loading ] && PHASE=menu
    grep -q "RAMTEST: in game" /tmp/game.log && PHASE=game
    RSS=$(awk "/^VmRSS/{print \$2}" /proc/$PID/status)
    ANON=$(awk "/^RssAnon/{print \$2}" /proc/$PID/status)
    FILE=$(awk "/^RssFile/{print \$2}" /proc/$PID/status)
    echo "$T,$RSS,$ANON,$FILE,$PHASE" >> /out/ram.csv
    [ $PHASE = menu ] && MENU_KB=$RSS
    [ $PHASE = game ] && [ $START_KB = 0 ] && START_KB=$RSS
done
PEAK=$(awk "/^VmHWM/{print \$2}" /proc/$PID/status 2>/dev/null || echo 0)
END_KB=$(awk "/^VmRSS/{print \$2}" /proc/$PID/status 2>/dev/null || echo 0)
xwd -root -display :1 2>/dev/null | convert xwd:- /out/shot.png 2>/dev/null || true
kill $PID 2>/dev/null; sleep 1
MAPSIZE=$(grep -o "RAMTEST: map size [0-9]*x[0-9]* players [0-9]*" /tmp/game.log | head -1 | sed "s/RAMTEST: map size //")
MAXDAY=$(grep -o "at day [0-9]*" /tmp/game.log | awk "{print \$3}" | sort -n | tail -1)
REACHED=false; grep -q "RAMTEST: in game" /tmp/game.log && REACHED=true
grep -v "Registering ressource\|Frame skipped" /tmp/game.log | tail -400 > /out/game.log
grep -E "Critical|Fatal|RAMTEST" /tmp/game.log | head -50 > /out/markers.log || true
cat > /out/summary.json <<EOF
{
  "git_rev": "$GIT_REV",
  "map": "$MAP_FOLDER$MAP_FILE",
  "map_size_and_players": "${MAPSIZE:-unknown}",
  "menu_only": $([ "$MENU_ONLY" = 1 ] && echo true || echo false),
  "seconds_requested": $SECONDS_TO_RUN,
  "seconds_run": $T,
  "final_phase": "$PHASE",
  "reached_game": $REACHED,
  "max_day_reached": ${MAXDAY:-0},
  "menu_rss_mb": $((MENU_KB/1024)),
  "game_start_rss_mb": $((START_KB/1024)),
  "end_rss_mb": $((END_KB/1024)),
  "peak_rss_mb": $((PEAK/1024)),
  "target_peak_mb": 700,
  "renderer": "Mesa llvmpipe under Xvfb 640x480 (textures counted in RSS)"
}
EOF
cat /out/summary.json
'
echo "Receipts: $OUT"
