#!/usr/bin/env bash
# guide.sh <turns.jsonl> <segment> [focus] [prev-guide-json]
# Builds the condensed view, asks Sonnet for a guide, prints one guide record (or an error record).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
GUIDE_TEXT_MAX=4000   # chars per user/assistant turn sent to Sonnet
GUIDE_TOOL_MAX=600    # chars per tool result sent to Sonnet
GUIDE_INPUT_MAX=600000

turns="$1"; segment="$2"; focus="${3:-}"; prev="${4:-}"
first="$("$JQ" -s 'first.n' "$turns")"; last="$("$JQ" -s 'last.n' "$turns")"
created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

{
  if [ -n "$prev" ]; then
    printf 'Guide of the previous segment, for continuity only. The new guide covers turns %s-%s below and every turn number must fall in that range.\n%s\n\n--- new turns ---\n' "$first" "$last" "$prev"
  fi
  "$JQ" -r --argjson tmax "$GUIDE_TEXT_MAX" --argjson rmax "$GUIDE_TOOL_MAX" '
    (if .role == "tool" then .text[0:$rmax] else .text[0:$tmax] end) as $t
    | "[\(.n)] \(.role): \($t)"
      + (if .tools then "\n" + ([.tools[] | "  > \(.name)\(if .path then " path=" + .path else "" end) \(.input[0:200])"] | join("\n")) else "" end)
  ' "$turns"
} | head -c "$GUIDE_INPUT_MAX" > "$tmp/condensed.txt"

prompt="$(cat "$PLUGIN_ROOT/scripts/guide-prompt.md")"
[ -n "$focus" ] && prompt="$prompt
- Focus: $focus"

err=""; cost="null"; model=""
raw="$(env -u CLAUDECODE claude -p --model sonnet --tools "" --no-session-persistence \
        --disable-slash-commands --strict-mcp-config --system-prompt "$prompt" \
        --json-schema "$(cat "$PLUGIN_ROOT/scripts/guide-schema.json")" \
        --output-format json < "$tmp/condensed.txt" 2>"$tmp/err")" || err="claude exited $?: $(head -c 300 "$tmp/err")"
guide=""
if [ -z "$err" ]; then
  model="$(printf '%s' "$raw" | "$JQ" -r '(.modelUsage // {}) | keys | map(select(test("sonnet"))) | .[0] // ""' 2>/dev/null)"
  cost="$(printf '%s' "$raw" | "$JQ" -r '.total_cost_usd // null' 2>/dev/null)"
  guide="$(printf '%s' "$raw" | "$JQ" -c '.structured_output | select(type=="object")' 2>/dev/null)"
  if [ -z "$guide" ]; then
    text="$(printf '%s' "$raw" | "$JQ" -r '.result // ""' 2>/dev/null | sed -e '/^```/d')"
    guide="$(printf '%s' "$text" | "$JQ" -c 'select(type=="object")' 2>/dev/null)"
  fi
  [ -n "$guide" ] || err="guide was not valid JSON, raw saved to logs/"
fi
if [ -n "$err" ]; then
  mkdir -p "$PLUGIN_ROOT/logs"
  { echo "$err"; echo "--- stderr"; cat "$tmp/err"; echo "--- raw"; printf '%s\n' "$raw"; } > "$PLUGIN_ROOT/logs/guide-seg${segment}-${created}.txt"
fi

if [ -n "$guide" ]; then
  printf '%s' "$guide" | "$JQ" -c --argjson seg "$segment" --arg created "$created" --arg model "$model" --argjson cost "${cost:-null}" \
    '{type:"guide", segment:$seg, created:$created, model:$model, cost_usd:$cost} + .'
else
  "$JQ" -n -c --argjson seg "$segment" --arg created "$created" --arg err "$err" \
    '{type:"guide", segment:$seg, created:$created, error:$err}'
fi
