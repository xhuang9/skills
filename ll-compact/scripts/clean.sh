#!/usr/bin/env bash
# Lists or deletes dump files whose session is no longer loaded anywhere.
#   clean.sh            dry run: table only
#   clean.sh --yes      delete what the rules select
#   clean.sh --days N   also select dumps older than N days whose session is not live
# Rules: a live session (registered in ~/.claude/sessions with a running pid) is always kept.
# A dead session whose original transcript is gone from ~/.claude/projects is deleted:
# Claude Code has already made it unresumable. Otherwise keep, unless --days matches.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
yes=0; days=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) yes=1 ;;
    --days) days="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

live=""
for s in "$HOME"/.claude/sessions/*.json; do
  [ -f "$s" ] || continue
  pid="$("$JQ" -r '.pid // empty' "$s")"; sid="$("$JQ" -r '.sessionId // empty' "$s")"
  [ -n "$pid" ] && [ -n "$sid" ] && kill -0 "$pid" 2>/dev/null && live="$live $sid"
done

now="$(date +%s)"
printf '%-38s %-28s %4s %8s %5s %5s %5s  %s\n' SESSION PROJECT SEGS SIZE LIVE SRC AGE ACTION
selected=()
for f in "$DATA_ROOT"/*/*.jsonl; do
  [ -f "$f" ] || continue
  sid="$(basename "$f" .jsonl)"; proj="$(basename "$(dirname "$f")")"
  segs="$(grep -c '"type":"meta"' "$f")"
  size="$(du -h "$f" | cut -f1)"
  islive=no; case " $live " in *" $sid "*) islive=yes ;; esac
  src=no; [ -f "$HOME/.claude/projects/$proj/$sid.jsonl" ] && src=yes
  age=$(( (now - $(stat -f %m "$f")) / 86400 ))
  action=keep
  if [ "$islive" = no ]; then
    if [ "$src" = no ]; then action=delete
    elif [ -n "$days" ] && [ "$age" -ge "$days" ]; then action=delete
    fi
  fi
  printf '%-38s %-28s %4s %8s %5s %5s %4sd  %s\n' "$sid" "${proj:0:28}" "$segs" "$size" "$islive" "$src" "$age" "$action"
  [ "$action" = delete ] && selected+=("$f")
done

echo
if [ "${#selected[@]}" -eq 0 ]; then echo "Nothing to delete."; exit 0; fi
if [ "$yes" -eq 1 ]; then
  for f in "${selected[@]}"; do rm -f "$f"; rmdir "$(dirname "$f")" 2>/dev/null; done
  echo "Deleted ${#selected[@]} file(s)."
else
  echo "${#selected[@]} file(s) selected. Re-run with --yes to delete."
fi
