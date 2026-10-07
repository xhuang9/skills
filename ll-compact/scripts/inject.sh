#!/usr/bin/env bash
# SessionStart hook (compact, resume). Pure shell: prints the segment guides for
# this session so the fresh context knows where the lossless dump is and when to read it.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
input="$(cat)"
session="$(printf '%s' "$input" | "$JQ" -r '.session_id')"
transcript="$(printf '%s' "$input" | "$JQ" -r '.transcript_path')"
f="$(data_path "$transcript" "$session")"
[ -s "$f" ] || exit 0
"$JQ" -r -s --arg path "$f" -f "$PLUGIN_ROOT/scripts/render.jq" "$f"
