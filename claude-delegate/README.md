# claude-delegate

`claude-delegate` is a Codex skill for handing a narrowly scoped subtask to the local Claude CLI and folding the result back into the current task.

It is designed for cases where a second model pass is useful, but the work is still bounded enough that the prompt, file scope, and expected output can stay small and explicit.

## What This Skill Is For

- Delegating a focused code review or diff review
- Running a read-only investigation against a known set of files
- Asking Claude for a second opinion on a design or implementation choice
- Producing a compact structured summary, checklist, or JSON result
- Estimating whether it is safe to spend Claude usage before making a real request

## What This Skill Is Not For

- Open-ended repository exploration
- Large feature implementation handoff
- Interactive Claude TUI workflows such as `/usage`
- Broad prompts that require a long transcript or a large architecture dump

## How It Works

The skill provides a small workflow around Claude CLI:

1. Check whether the task is a good candidate for delegation.
2. Optionally estimate current Claude usage pressure from local history.
3. Run a usage gate to decide whether to delegate, confirm with the user, or skip.
4. Execute a non-interactive Claude CLI prompt with a narrow scope.
5. Bring the result back into the current Codex task and verify it locally.

## Included Files

- `SKILL.md`
  The main instructions for when and how to use the skill.
- `scripts/check_usage.py`
  A small gate that inspects local Claude telemetry and can run a tiny probe request.
- `scripts/estimate_usage.py`
  A no-cost heuristic that estimates usage pressure from local Claude history.
- `scripts/delegate.sh`
  A wrapper for non-interactive `claude -p` runs.
- `agents/openai.yaml`
  A lightweight skill metadata file.

## Requirements

- Claude CLI installed and authenticated
- Python 3 available for the helper scripts
- Access to local Claude telemetry under `~/.claude/`

## Typical Usage

Run the usage estimate:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/estimate_usage.py
```

Run the gate:

```bash
python3 ~/.codex/skills/claude-delegate/scripts/check_usage.py --probe
```

Delegate a scoped task:

```bash
~/.codex/skills/claude-delegate/scripts/delegate.sh \
  --model sonnet \
  --cwd ~/project \
  -- "Review this diff for blocking regressions. Output 3 bullets max."
```

## Design Principles

- Keep the delegated task narrow.
- Name the exact files when possible.
- Ask for short outputs.
- Treat Claude output as advisory until it has been verified locally.

## Best Fit

This skill works best when the calling agent already understands the surrounding codebase and only wants to offload one bounded subtask, especially a review, diagnosis, extraction, or cross-check.
