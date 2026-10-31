#!/usr/bin/env bash
# A capped build: run a command under a wall-clock cap and a memory cap, sampling peak RSS.
#   CAP=1800 MEM=10G run_capped.sh <log> <command...>
# The last line of <log> is "exit <code> after <s> s, peak RSS <MiB> MiB". Exit 124 is the time cap;
# a kill with no Julia error is the memory cap.
set -u
log=$1
shift
start=$(date +%s)
timeout "${CAP:-1800}" systemd-run --user --scope -q -p MemoryMax="${MEM:-10G}" -p MemorySwapMax=0 \
  "$@" > "$log" 2>&1 &
pid=$!
peak=0
while kill -0 "$pid" 2>/dev/null; do
  r=$(pgrep -P "$pid" -f . | xargs -r ps -o rss= -p 2>/dev/null | sort -n | tail -1)
  r=${r// /}
  [ -n "$r" ] && [ "$r" -gt "$peak" ] && peak=$r
  sleep 5
done
wait "$pid"
code=$?
echo "exit $code after $(( $(date +%s) - start )) s, peak RSS $(( peak / 1024 )) MiB" >> "$log"
exit "$code"
