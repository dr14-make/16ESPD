#!/usr/bin/env bash
# Prove a layout change touched nothing but layout: drop every `metadata { ... }` block and every
# `{^tag}` link, then diff each file against <base>. Silent and exit 0 when only layout changed.
# Inline `{"Dyad": ...}` annotations on a declaration are not stripped; move them into `_links`.
# Usage: metadata-only.sh <base-rev> <file.dyad>...
set -uo pipefail
base=$1
shift
strip() { awk '/^metadata \{/{skip=1} skip&&/^end/{skip=0} !skip' | sed -E 's/ \{\^[A-Za-z0-9_]+\}//g'; }

status=0
for f in "$@"; do
  diff -u --label "$base:$f" --label "$f" \
    <(git show "$base:$f" 2>/dev/null | strip) <(strip < "$f") || status=1
done
exit $status
