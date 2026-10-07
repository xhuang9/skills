#!/usr/bin/env bash
# PreCompact hook. Runs only when the user typed `/compact ll` (or `/compact ll <focus>`).
# Appends the not-yet-dumped transcript turns plus a Sonnet-written guide to
# projects/<encoded-cwd>/<session-id>.jsonl, then lets compaction proceed.
# Always exits 0: a failure here must never block compaction.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
RESULT_MAX=20000      # chars kept per tool result and per tool input in the dump

input="$(cat)"
custom="$(printf '%s' "$input" | "$JQ" -r '.custom_instructions // ""' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$custom" in
  ll|ll\ *) ;;
  *) exit 0 ;;
esac
focus="${custom#ll}"; focus="${focus# }"

session="$(printf '%s' "$input" | "$JQ" -r '.session_id')"
transcript="$(printf '%s' "$input" | "$JQ" -r '.transcript_path')"
cwd="$(printf '%s' "$input" | "$JQ" -r '.cwd')"
say() { printf '{"systemMessage":"ll-compact: %s"}\n' "$1"; }

[ -f "$transcript" ] || { say "transcript not found, nothing dumped"; exit 0; }
out="$(data_path "$transcript" "$session")"
mkdir -p "$(dirname "$out")"

last_line=0; last_turn=0; segment=1; prev=""
if [ -s "$out" ]; then
  read -r last_line last_turn segment < <("$JQ" -s -r '
    ([.[] | select(.type=="meta")] | last) as $m
    | ([.[] | select(.type=="turn")] | last) as $t
    | "\($m.lines[1] // 0) \($t.n // 0) \(($m.segment // 0) + 1)"' "$out")
  prev="$("$JQ" -c 'select(.type=="guide" and .error==null) | {summary, decisions, state, open}' "$out" | tail -1)"
fi
total="$(wc -l < "$transcript" | tr -d ' ')"
[ "$total" -lt "$last_line" ] && last_line=0   # transcript was rewritten, start over
if [ "$total" -le "$last_line" ]; then say "no new turns since segment $((segment-1))"; exit 0; fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
tail -n +"$((last_line + 1))" "$transcript" \
  | "$JQ" -c -s --argjson n0 "$last_turn" --argjson seg "$segment" --argjson max "$RESULT_MAX" \
      -f "$PLUGIN_ROOT/scripts/turns.jq" > "$tmp/turns.jsonl"
count="$(wc -l < "$tmp/turns.jsonl" | tr -d ' ')"
if [ "$count" -eq 0 ]; then say "no new turns since segment $((segment-1))"; exit 0; fi
first_turn=$((last_turn + 1)); new_last=$((last_turn + count))
created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

guide="$(bash "$PLUGIN_ROOT/scripts/guide.sh" "$tmp/turns.jsonl" "$segment" "$focus" "$prev")"
model="$(printf '%s' "$guide" | "$JQ" -r '.model // ""')"
cost="$(printf '%s' "$guide" | "$JQ" -r '.cost_usd // null')"
err="$(printf '%s' "$guide" | "$JQ" -r '.error // ""')"

{
  "$JQ" -n -c --arg s "$session" --arg cwd "$cwd" --arg created "$created" --arg tr "$transcript" \
    --arg model "$model" --argjson seg "$segment" --argjson cost "${cost:-null}" \
    --argjson l0 "$((last_line + 1))" --argjson l1 "$total" --argjson t0 "$first_turn" --argjson t1 "$new_last" \
    '{type:"meta", segment:$seg, session:$s, cwd:$cwd, created:$created, transcript:$tr,
      lines:[$l0,$l1], turns:[$t0,$t1], model:$model, cost_usd:$cost}'
  printf '%s\n' "$guide"
  cat "$tmp/turns.jsonl"
} >> "$out"

if [ -n "$err" ]; then
  say "segment $segment, turns $first_turn-$new_last dumped, guide failed ($err) -> $out"
else
  say "segment $segment, turns $first_turn-$new_last, guide by ${model:-sonnet} -> $out"
fi
exit 0
