# Input: slurped array of raw transcript records (only the lines not yet dumped).
# Output: one "turn" record per line. $n0 = last turn number already dumped,
# $seg = segment number, $max = chars kept per tool result and per tool input.
def txt:
  if type == "string" then .
  elif type == "array" then [ .[] | select(type == "object" and .type == "text") | .text ] | join("\n")
  else "" end;

def tool:
  (.input | tostring) as $i
  | {name, path: (.input.file_path // .input.path // .input.notebook_path // null), input: $i[0:$max]}
  + (if ($i | length) > $max then {ilen: ($i | length)} else {} end)
  | with_entries(select(.value != null));

[ .[]
  | select(.type == "user" or .type == "assistant")
  | select(.isSidechain != true and .isMeta != true and .message != null)
  | . as $r
  | (.message.content) as $c
  | ( if ($c | type) == "string" then {role: $r.type, text: $c}
      else
        ([ $c[] | select(.type == "text") | .text ] | join("\n")) as $text
        | ([ $c[] | select(.type == "tool_use") | tool ]) as $tools
        | ([ $c[] | select(.type == "tool_result") | (.content | txt) ] | join("\n")) as $res
        | if ($tools | length) > 0 then {role: "assistant", text: $text, tools: $tools}
          elif ($res | length) > 0 then {role: "tool", text: $res[0:$max], len: ($res | length)}
          elif ($text | length) > 0 then {role: $r.type, text: $text}
          else empty end
      end )
  | if $r.isCompactSummary == true then .role = "compact-summary" else . end
  | if .len != null and .len <= $max then del(.len) else . end
  | . + {ts: $r.timestamp}
]
| to_entries
| map({type: "turn", n: (.key + 1 + $n0), seg: $seg} + .value)
| .[]
