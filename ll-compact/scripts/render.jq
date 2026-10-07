# Input: slurped dump file. Output: the text injected after compaction.
def ref: "[\(.t)] \(.what)";
def sect(title; xs; f): if (xs // []) | length > 0 then "\n  \(title):\n" + (xs | map("  - " + f) | join("\n")) else "" end;
def seg:
  "Segment \(.m.segment) · \(.m.created) · turns \(.m.turns[0])-\(.m.turns[1])"
  + (if .g.error then "\n  (guide failed: \(.g.error))"
     else "\n  \(.g.summary)"
       + sect("decisions"; .g.decisions; if type == "object" then "[\(.t)] \(.by): \(.what)" else . end)
       + sect("corrections"; .g.corrections; ref)
       + sect("where"; .g.toc; "\(.topic) [\(.turns)\(if .key then " · key " + (.key | map(tostring) | join(",")) else "" end)]: \(.when)")
       + sect("artifacts"; .g.artifacts; "[\(.t)] \(.path): \(.what)")
       + sect("state as of the dump, verify before relying on it"; .g.state; ref)
       + sect("open"; .g.open; if type == "object" then ref else . end)
     end);

([.[] | select(.type=="meta")]) as $metas
| ([.[] | select(.type=="guide")]) as $guides
| ([.[] | select(.type=="turn")] | length) as $n
| "ll-compact: the context before this compaction is kept losslessly in\n  F=\($path)\n"
  + "\($n) turns in \($metas | length) segment(s). Later segments supersede earlier ones. "
  + "Numbers in brackets are turn numbers. Pull exact turns, never the whole file:\n"
  + "  jq -r 'select(.type==\"turn\" and (.n|IN(12,40))) | \"[\\(.n)] \\(.role): \\(.text)\"' \"$F\"\n"
  + "Range: .n>=A and .n<=B with .text[0:1500]. More recipes: skill ll-compact.\n\n"
  + ($metas | map(. as $m | {m: $m, g: ($guides | map(select(.segment == $m.segment)) | last // {})} | seg) | join("\n\n"))
