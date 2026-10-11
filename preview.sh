#!/usr/bin/env bash
# Muestra la statusline con datos de ejemplo, sin abrir Claude Code.
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NOW=$(date +%s)
for pct in 27 64 91; do
  printf '{"model":{"display_name":"Fable 5.1"},"effort":{"level":"high"},"session_name":"statusline para claude code","context_window":{"used_percentage":%s},"rate_limits":{"five_hour":{"used_percentage":21,"resets_at":%s},"seven_day":{"used_percentage":5,"resets_at":%s}}}' \
    "$pct" $((NOW+3600)) $((NOW+3*86400)) | COLUMNS=${COLUMNS:-100} "$DIR/statusline.sh"
  echo
done
