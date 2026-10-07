# ll-compact

Lossless compact for Claude Code. `/compact ll` keeps the whole conversation on disk before compaction and puts a short retrieval guide back into the fresh context, so an agent can pull the original turns instead of working from the summary alone. A bare `/compact` behaves exactly as before.

## Why it exists

Built-in `/compact` sends the transcript to the model with a summarisation prompt and replaces the history with the result. The summary is lossy. Decisions get paraphrased, exact commands and file contents disappear, and nothing in the new context says where the original text went.

The transcript still exists at `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`, but Claude Code deletes it after its cleanup period and the model never sees that path. This plugin copies the turns somewhere durable, adds an index a model can act on, and tells the post-compaction context where to look.

## Concepts

**Segment.** One `/compact ll` run. Each run appends only the turns that were not dumped before, so a session compacted three times has three segments in one file. Later segments describe later work and supersede earlier ones when guides disagree.

**Turn.** One transcript message: a user prompt, an assistant reply, a batch of tool calls, or a tool result. Turn numbers are global across segments and never reused, so a guide entry such as `turns 41-52` is stable for the life of the session.

**Guide.** A Sonnet-written index per segment. Every entry carries a turn number, so a future agent reads one turn instead of a range: a summary, a table of contents mapping topics to turn ranges plus the one to three `key` turns that hold each topic's payload, the decisions the user stated with the turn where they said it, corrections (an earlier belief found wrong and where it was fixed), artifacts (files, tickets, commits and the turn holding their final version), state snapshots that may have moved since, and open items. Output is enforced with a JSON schema through the CLI's structured-output flag. The guide is small enough to sit in context permanently.

**Trigger token.** The text after `/compact` reaches the PreCompact hook as `custom_instructions`. The hook acts only when that text is `ll` or starts with `ll `. Anything after `ll` becomes a focus hint for the guide writer. This keeps the behaviour opt-in per keystroke without a separate skill.

**Pure-code injection.** The post-compaction step is shell and jq only. It runs on every compaction and resume and costs milliseconds. The only model call happens inside the `/compact ll` path.

## Hooks

Declared in `hooks/hooks.json`.

| event | matcher | script | timeout | does |
|---|---|---|---|---|
| `PreCompact` | `manual` | `scripts/dump.sh` | 600 s | Exits unless the trigger token is present. Otherwise appends new turns and a guide to the dump file, then prints a `systemMessage` line. Always exits 0, so a failure never blocks compaction. |
| `SessionStart` | `compact\|resume` | `scripts/inject.sh` | 10 s | Prints the segment guides for this session to stdout. Claude Code adds SessionStart stdout to context. Prints nothing when no dump exists. |

Both hooks receive JSON on stdin with `session_id`, `transcript_path` and `cwd`. The dump path is derived from `transcript_path`, so the data folder mirrors Claude Code's own layout.

## Files

```
.claude-plugin/plugin.json      manifest, loaded in place as ll-compact@skills-dir
hooks/hooks.json                the two hooks above
SKILL.md                        skill "ll-compact": format and jq recipes for reading a dump
skills/ll-compact-clean/        skill "ll-compact-clean": housekeeping
scripts/lib.sh                  shared paths and the data_path helper
scripts/dump.sh                 PreCompact handler
scripts/turns.jq                transcript records to turn records
scripts/guide.sh                condensed view, Sonnet call, guide record
scripts/guide-prompt.md         system prompt for the guide writer
scripts/guide-schema.json       JSON schema the guide must satisfy
scripts/regen.sh                rewrite the guide for one segment without compacting
scripts/inject.sh               SessionStart handler
scripts/render.jq               dump file to the injected text block
scripts/clean.sh                lists or deletes dumps with no loadable session
projects/                       data, gitignored
logs/                           raw output of failed guide calls, gitignored
```

## Data format

One file per session: `projects/<encoded-cwd>/<session-id>.jsonl`. One JSON object per line, appended in timeline order.

| type | fields |
|---|---|
| `meta` | `segment`, `session`, `cwd`, `created`, `transcript`, `lines` (transcript line range this segment covers), `turns` (turn range), `model`, `cost_usd` |
| `guide` | `segment`, `created`, `model`, `cost_usd`, `summary`, `toc[]` with `topic`, `turns`, `key[]`, `when`; `decisions[]` with `t`, `by`, `what`; `corrections[]`, `state[]`, `open[]` with `t`, `what`; `artifacts[]` with `t`, `path`, `what`. On failure: `error` instead. A segment can have several guide records; the last one is current. |
| `turn` | `n`, `seg`, `role` (`user`, `assistant`, `tool`, `compact-summary`), `ts`, `text`, `tools[]` with `name`, `path` (when the call names a file), `input` and `ilen` when cut at 20,000 chars, `len` only when a tool result was cut at 20,000 chars |

Records that are skipped: sidechain messages from subagents, meta records, thinking blocks, and non-message records such as permission-mode changes.

## Flow

1. You type `/compact ll`.
2. `dump.sh` reads the last `meta` record for the cursor, tails the transcript from the next line, converts the new records to turns, and builds a condensed text view (user and assistant text capped at 4,000 chars, tool results at 600).
3. It calls `claude -p --model sonnet` headlessly with the guide prompt as the system prompt and `guide-schema.json` as the structured-output schema. Tools, skills and MCP servers are disabled and the helper session is not persisted. From segment two on, the previous guide is prepended for continuity. A failed call leaves a `guide` record with `error` and the raw output under `logs/`.
4. It appends `meta`, `guide` and the turns to the dump file and prints one status line.
5. Built-in compaction runs.
6. `inject.sh` prints every segment's guide plus the file path and one jq recipe into the new context.
7. An agent that needs detail follows the guide to a turn range and reads it with jq. The `ll-compact` skill carries the recipes.

## Things learned while building it

- `CLAUDE_CODE_SESSION_ID` is set in the Bash environment. Hooks get the same id on stdin, so nothing has to guess which transcript is current.
- The PreCompact input schema is `trigger: manual | auto` and `custom_instructions: string | null`. Confirmed in the docs and in the 2.1.270 binary.
- `SessionStart` accepts `startup`, `resume`, `clear`, `compact` and `fork` as matcher values, and its stdout becomes context. PostCompact exists but its stdout does not.
- A nested `claude -p` works from inside a hook once `CLAUDECODE` is removed from the environment. `--bare` is not usable here because it restricts auth to an API key.
- `claude plugin init <name>` scaffolds under `~/.claude/skills/` and loads the folder in place. There is no cache copy, which is why data can live inside the plugin folder.
- `~/.claude/sessions/<pid>.json` is a registry of running sessions with `sessionId` and `pid`. The clean script uses it, plus a `kill -0` check, to decide what is live.
- Free-form JSON from the model broke once on a 650-turn session (an unescaped quote inside a string). `--json-schema` returns a validated object in `structured_output`, which removed that failure.
- The transcript file is written asynchronously and can lag the in-memory conversation by a message. In practice `/compact ll` is typed after a turn ends, so the lag is at most the command echo itself.

## Cost

The only expense is one Sonnet call per `/compact ll` or regen. Observed: about fifteen cents for a 52-turn segment, four cents for a nine-turn follow-up, and fifty-six cents for a 650-turn session. Each `meta` and `guide` record stores `cost_usd`.

## Testing without compacting

Pipe a fake hook payload into either script. The transcript path for the current session is the newest file in the matching `~/.claude/projects` folder.

```bash
T=~/.claude/projects/<encoded-cwd>/<session-id>.jsonl
printf '{"session_id":"<session-id>","transcript_path":"%s","cwd":"%s","hook_event_name":"PreCompact","trigger":"manual","custom_instructions":"ll"}' "$T" "$PWD" \
  | bash ~/.claude/skills/ll-compact/scripts/dump.sh
printf '{"session_id":"<session-id>","transcript_path":"%s","cwd":"%s","hook_event_name":"SessionStart","source":"compact"}' "$T" "$PWD" \
  | bash ~/.claude/skills/ll-compact/scripts/inject.sh
```

## Regenerating a guide

`bash scripts/regen.sh <dump> [segment] [focus]` rebuilds the guide for one segment from the turns already in the dump and appends it. The renderer picks the latest guide per segment. Use it after a failed call or a prompt change; the next compaction or resume injects the new guide.

## Housekeeping

`bash scripts/clean.sh` prints a table of dumps with live status, whether the source transcript still exists, age and the action the rules would take. `--yes` deletes the selected rows. `--days N` also selects dead sessions older than N days. The `ll-compact-clean` skill wraps this and asks for confirmation before deleting.

## Requirements

bash, jq, and the `claude` CLI on PATH. Tested on Claude Code 2.1.270 on macOS.
