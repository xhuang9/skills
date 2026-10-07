#!/usr/bin/env bash
# regen.sh <dump.jsonl> [segment] [focus]
# Rewrites the guide for one segment (default: the last) from the turns already in the dump.
# Appends a new guide record; the renderer uses the latest guide per segment.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
dump="$1"; segment="${2:-}"; focus="${3:-}"
[ -s "$dump" ] || { echo "no such dump: $dump" >&2; exit 1; }
[ -n "$segment" ] || segment="$("$JQ" -s '[.[] | select(.type=="meta")] | last | .segment' "$dump")"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
"$JQ" -c --argjson seg "$segment" 'select(.type=="turn" and .seg==$seg)' "$dump" > "$tmp/turns.jsonl"
[ -s "$tmp/turns.jsonl" ] || { echo "segment $segment has no turns" >&2; exit 1; }
prev=""
[ "$segment" -gt 1 ] && prev="$("$JQ" -c --argjson s "$((segment - 1))" 'select(.type=="guide" and .segment==$s and .error==null) | {summary, decisions, state, open}' "$dump" | tail -1)"
guide="$(bash "$PLUGIN_ROOT/scripts/guide.sh" "$tmp/turns.jsonl" "$segment" "$focus" "$prev")"
printf '%s\n' "$guide" >> "$dump"
printf '%s' "$guide" | "$JQ" -r 'if .error then "guide failed: \(.error)" else "segment \(.segment): guide by \(.model), cost \(.cost_usd)" end'
