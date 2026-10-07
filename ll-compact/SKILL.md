---
name: ll-compact
description: Lossless compact. Use when the context contains an "ll-compact:" block pointing at a dump file, when an answer needs detail from before a compaction (earlier decisions, exact commands, file contents, what the user said), or when the user says "compact ll", "lossless compact", "read the original context", "check the dump", "what did we discuss before the compact". Also explains how `/compact ll` works and where dumps live.
---

# ll-compact

`/compact ll` keeps the whole conversation before compaction. A PreCompact hook appends every not-yet-dumped turn plus a Sonnet-written retrieval guide to one JSONL file per session. After compaction a SessionStart hook prints the guides back into the fresh context. A bare `/compact` does none of this.

Dump location, mirroring Claude Code's own layout:

```
~/.claude/skills/ll-compact/projects/<encoded-cwd>/<session-id>.jsonl
```

## Record types

One JSON object per line, appended in timeline order.

| type | fields | one per |
|---|---|---|
| `meta` | `segment`, `session`, `cwd`, `created`, `transcript`, `lines` (transcript line range), `turns` (turn range), `model` | `/compact ll` run |
| `guide` | `segment`, `created`, `model`, `cost_usd`, `summary`, `toc[]` (`topic`, `turns` range, `key[]` payload turns, `when`), `decisions[]` (`t`, `by`, `what`), `corrections[]` (`t`, `what`), `artifacts[]` (`t`, `path`, `what`), `state[]` (`t`, `what`), `open[]` (`t`, `what`), or `error` | `/compact ll` run, plus one per regen |
| `turn` | `n` (global, never reused), `seg`, `role` (`user`, `assistant`, `tool`, `compact-summary`), `ts`, `text`, `tools[]` (`name`, `path`, `input`, `ilen` when cut), `len` (only when a tool result was cut) | conversation message |

Every `t` and every `key` entry is a turn number. `key` names the one to three turns that hold the payload of a topic: the user's own words, the tool call that wrote a file, the tool result with the command output. Read those before reading the range.

Turn numbers keep counting across segments. A later segment describes later work, so when guides disagree the later one is current. When a segment has more than one guide record, the last one is current.

`state` entries are snapshots. A ticket, branch or deploy can move after the dump, so verify against the board, git or the service before relying on one.

## Reading rules

1. Read the guide first. The injected block already has it; otherwise `jq -c 'select(.type=="guide")' <file> | tail -1`.
2. Pull the `key` turns or the `t` turn named by the entry (recipe 1). Widen to the `toc` range only when the key turns are not enough (recipe 2). Never `cat` the file: tool results can be thousands of characters each.
3. Cut long text at the jq level, not after loading it.
4. If the guide has `error`, list user turns to locate the topic (recipe 4), or regenerate it (Housekeeping).

## Recipes

```bash
F=~/.claude/skills/ll-compact/projects/<encoded-cwd>/<session-id>.jsonl

# 1. exact turns, in full
jq -r 'select(.type=="turn" and (.n|IN(131,338))) | "[\(.n)] \(.role): \(.text)"' "$F"

# 2. turns A to B, text capped at 1500 chars each
jq -r 'select(.type=="turn" and .n>=A and .n<=B) | "[\(.n)] \(.role): \(.text[0:1500])"' "$F"

# 3. the file a tool call wrote, from the call's own input
jq -r 'select(.type=="turn" and .n==N) | .tools[] | "\(.name) \(.path // "")\n\(.input)"' "$F"

# 4. every user message, first line only: a cheap timeline
jq -r 'select(.type=="turn" and .role=="user") | "[\(.n)] \(.text | split("\n")[0][0:120])"' "$F"

# 5. find the turns that mention a term
jq -r 'select(.type=="turn" and (.text | test("TERM"; "i"))) | "[\(.n)] \(.role)"' "$F"

# 6. tool calls only: what ran, what was edited
jq -r 'select(.type=="turn" and .tools) | .tools[] | "[\(input.n)] \(.name) \(.path // .input[0:120])"' "$F"
```

## Housekeeping

`/ll-compact-clean` lists dumps whose session is no longer running and deletes the ones Claude Code can no longer resume.

`bash ~/.claude/skills/ll-compact/scripts/regen.sh <file> [segment] [focus]` rewrites the guide for one segment from the turns already dumped, without compacting. Use it after a guide failure or when the guide prompt has improved. The new guide is injected at the next compaction or resume.
