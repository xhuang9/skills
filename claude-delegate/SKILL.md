---
name: claude-delegate
description: Use when the user wants to delegate a scoped subtask to the locally installed Claude CLI or Claude Code subscription, especially for second-opinion analysis, structured summaries, prompt-based code review, or isolated planning. Prefer this skill for non-interactive `claude -p` runs, and do not use it for TUI-only slash commands such as `/usage`.
---

# Claude Delegate

Use this skill to hand an isolated subtask to the user's local Claude CLI and fold the result back into the current task. Keep the delegated task narrow and verifiable.

## When To Use

- The user explicitly asks to use Claude or Claude CLI.
- A second model pass is useful for review, summarization, extraction, or planning.
- The task is a clearly scoped code change with bounded context, and delegating it is likely to save Codex tokens.
- The subtask can be expressed as a self-contained prompt.
- Structured output such as JSON or a checklist would help.

## When Not To Use

- Codex can handle the work directly without extra latency or cost.
- The task depends on Claude's interactive TUI or slash panels such as `/usage` or `/model`.
- The delegated task needs open-ended repo exploration with unclear bounds.
- The task would require shipping a large amount of context to Claude and then reloading a large result back into Codex.
- Claude CLI auth or network access is unavailable.

## Invoke Policy

Auto-delegate only when all of the following are true:

- The task is a focused code edit, review, summary, extraction, or cross-check.
- The relevant context is already known and can be named precisely.
- Expected Claude output is compact enough to fold back into the current turn.

Good auto-delegation candidates:

- Fix or refactor in a known file or a small feature folder
- Focused diff review
- Cross-validation when the user explicitly asks for a second opinion
- Structured extraction from a bounded document or command output
- Read-only investigation or root-cause analysis when the exact files are already known

Avoid auto-delegation when any of the following are true:

- You would need to paste broad architecture context or a long conversation history
- The task is open-ended exploration or large-scale implementation planning
- The expected Claude output would be long, file-by-file, or transcript-like
- The user is asking for a large code artifact that Codex would still need to inspect in full

Practical thresholds:

- Prefer delegating when the prompt can stay under roughly 12k characters
- Prefer delegating when context is no more than about 8 files or one small feature area
- Prefer delegating when the requested output can stay under roughly 2k characters

Model hint:

- Prefer `opus 4.6 high` for read-only diagnosis, root-cause analysis, or code search tasks when the relevant files are explicitly named and the user wants deeper reasoning rather than code edits.
- Prefer `sonnet` for lighter review, summarization, extraction, or small scoped implementation help.

## Usage Gate

Before delegating a candidate task, run [`scripts/check_usage.py`](./scripts/check_usage.py).

Decision policy:

- `delegate`: Safe to use Claude now
- `confirm`: Ask the user to confirm current usage before using Claude
- `skip`: Do not use Claude for this task

How `check_usage.py` decides:

- It can run a tiny `Reply with exactly: OK` probe against Claude CLI
- It also reads the latest local telemetry limits events from `~/.claude/telemetry`
- It maps the result to:
  - `allowed` -> `delegate`
  - `allowed_warning` -> `confirm`
  - `rejected` or a rate-limit probe failure -> `skip`

Important constraints:

- The probe itself consumes a tiny amount of Claude usage, so only run it after the task passes the invoke policy.
- Local telemetry is useful for a gate, not for exact percentages.
- We do not have a stable non-interactive equivalent of the TUI `/usage` panel.
- For Claude Pro, assume the primary constraint is the rolling 5-hour session limit unless the user says they regularly hit a higher-level cap.

## Usage Estimate

When you want a no-cost heuristic before probing, run [`scripts/estimate_usage.py`](./scripts/estimate_usage.py).

What it does:

- Reads deduplicated assistant message usage from `~/.claude/projects`
- Reads historical `allowed_warning` and `rejected` limit events from `~/.claude/telemetry`
- Computes weighted usage totals for recent windows such as `1h`, `3h`, `5h`, and `24h`
- Compares the current windows to historical warning and rejection windows

What it returns:

- `band`: `low`, `medium`, `high`, `critical`, or `unknown`
- `confidence`: how trustworthy the estimate is given the local sample size
- `current`: raw token sums and a weighted total per time window
- `ratios`: current weighted totals relative to historical warning and rejection medians

How to use it:

- `low`: safe to proceed to `check_usage.py --probe`
- `medium`: probe only if the task clearly passes the invoke policy
- `high`: prefer user confirmation before using Claude
- `critical`: skip Claude unless the user explicitly insists

Important constraints:

- This is not the same thing as the `/usage` panel percentage.
- It is a relative risk estimate against your own local history, not a direct quota meter.
- Repeated transcript updates are deduplicated by message id before summing.
- For Pro users, the `5h` window is the primary signal. `24h` is informational only and does not model a weekly cap.

## Workflow

1. Confirm Claude CLI availability if it has not already been verified in this thread.
   - `which claude`
   - `claude --version`
2. Decide whether the task passes the invoke policy.
3. Optionally run [`scripts/estimate_usage.py`](./scripts/estimate_usage.py) for a no-cost heuristic.
4. Run [`scripts/check_usage.py`](./scripts/check_usage.py) for a gate decision.
5. If the result is `skip`, continue in Codex and do not ask the user to confirm usage.
6. If the result is `confirm`, ask the user to confirm current Claude usage.
7. If the result is `delegate`, draft a narrow prompt with:
   - the exact objective
   - the allowed scope
   - the required output shape
   - any explicit constraints
   - the exact files Claude should inspect when this is a search/diagnosis task
8. Prefer non-interactive execution with [`scripts/delegate.sh`](./scripts/delegate.sh).
9. For real Claude calls, use `functions.exec_command` with `sandbox_permissions="require_escalated"` because Claude CLI needs external network access.
10. Prefer `--model` flags over slash commands.
11. For explicit-file investigations, default to a read-only prompt and tell Claude not to edit code.
12. Summarize the delegated result for the user instead of pasting a long raw transcript.

## Prompt Rules

- Name the exact files, paths, or excerpts Claude should consider.
- Ask for a fixed output format such as bullets, JSON, or a table.
- State what Claude must not do.
- Keep Claude outputs intentionally short to preserve the Codex token savings.
- Treat Claude output as advisory until you verify it locally.

## Gate Script

[`scripts/check_usage.py`](./scripts/check_usage.py) prints JSON and uses exit codes:

- `0` -> `delegate`
- `10` -> `confirm`
- `20` -> `skip`
- `30` -> internal error

Recommended Codex usage:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/check_usage.py --probe
```

Recommended manual usage without burning quota:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/check_usage.py --no-probe
```

Estimator usage:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/estimate_usage.py
```

## Wrapper Script

Use [`scripts/delegate.sh`](./scripts/delegate.sh) for common non-interactive runs.

Supported options:

- `--model <name>`
- `--cwd <dir>`
- `--output text|json|stream-json`
- `--system-prompt <text>`
- `--append-system-prompt <text>`
- `--max-budget-usd <amount>`
- `--json-schema-file <path>`
- `--permission-mode <mode>`
- `--allowed-tools <tools>`
- `--disallowed-tools <tools>`
- `--add-dir <dir>` (repeatable)
- `--prompt-file <path>`

Prompt input order:

1. `--prompt-file`
2. trailing arguments after `--`
3. stdin

## Examples

Review a scoped task:

```bash
~/.codex/skills/claude-delegate/scripts/delegate.sh \
  --model sonnet \
  --cwd ~/project \
  -- "Review this diff for blocking regressions. Output 3 bullets max."
```

Produce JSON:

```bash
~/.codex/skills/claude-delegate/scripts/delegate.sh \
  --model opus \
  --output json \
  --json-schema-file /tmp/review-schema.json \
  --prompt-file /tmp/review-prompt.txt
```

Gate first, then delegate:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/estimate_usage.py
python3 ~/.codex/skills/claude-delegate/scripts/check_usage.py --probe
~/.codex/skills/claude-delegate/scripts/delegate.sh \
  --model sonnet \
  --cwd ~/project \
  -- "Review this diff for blocking regressions. Output 3 bullets max."
```

## Limits

- `claude -p "/usage"` does not return the interactive usage panel as plain output.
- The local telemetry gate can tell us `allowed`, `allowed_warning`, or `rejected`, but it is not an exact usage meter.
- Slash commands are not the stable interface for delegated runs.
- If the wrapper script is too restrictive, call `claude` directly with explicit flags.
