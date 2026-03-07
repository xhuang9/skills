# gemini-delegate

`gemini-delegate` is a Codex skill for handing a narrowly scoped subtask to the local Gemini CLI and folding the result back into the current task.

It is designed for cases where Gemini quota, local `GEMINI.md`, configured MCP servers, or browser-oriented tooling make Gemini a better execution engine than running the whole subtask inside Codex context.

## What This Skill Is For

- Delegating a focused summary, review, extraction, or diagnosis to Gemini CLI
- Checking whether current Gemini quota looks healthy before spending it
- Running browser-side inspections through Gemini when Chrome DevTools MCP is configured
- Producing compact JSON or checklist-style outputs from a tightly scoped prompt
- Offloading artifact-heavy tasks such as screenshots, Lighthouse audits, performance traces, or raw HTML extraction

## What This Skill Is Not For

- Open-ended repository exploration
- Large feature implementation handoff
- Interactive Gemini TUI workflows such as `/usage` or `/stats`
- Broad prompts that require a long transcript or large architecture dump
- A replacement for Codex when the task is mostly local editing and verification

## How It Works

The skill provides a small workflow around Gemini CLI:

1. Check whether the task is a good candidate for delegation.
2. Run a local quota gate using Gemini CLI's own internal auth and quota APIs.
3. Decide whether to delegate, confirm with the user, or skip.
4. Execute a non-interactive `gemini -p` prompt with a narrow scope.
5. Bring the result back into the current Codex task and verify it locally.

## Included Files

- `SKILL.md`
  The main instructions for when and how to use the skill.
- `scripts/check_usage.mjs`
  A quota gate that loads Gemini CLI internals and reports the detected tier, credits, and per-model quota fractions.
- `scripts/delegate.sh`
  A wrapper for non-interactive `gemini -p` runs.
- `scripts/suppress_console.cjs`
  A small console filter that removes Gemini startup noise from wrapped output.
- `agents/openai.yaml`
  A lightweight skill metadata file.

## Requirements

- Gemini CLI installed and authenticated
- Node.js available
- Access to the locally installed Gemini CLI package tree
- Optional: Chrome DevTools MCP or other Gemini MCP servers if you want browser or MCP-assisted workflows

## Typical Usage

Run the gate:

```bash
node ~/.codex/skills/gemini-delegate/scripts/check_usage.mjs --cwd ~/project
```

Delegate a scoped task:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  -- "Summarize the top three risks in this diff. Output JSON."
```

Delegate a Chrome-backed browser task:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  --allowed-mcp-server chrome-devtools \
  -- "Use Chrome DevTools MCP to capture a Lighthouse report and a screenshot for http://localhost:3000/."
```

## Local Configuration Policy

This repository copy intentionally excludes personal runtime configuration:

- No `~/.gemini/settings.json`
- No preconfigured auth state
- No bundled MCP server registrations
- No user-specific output directories

The skill assumes Gemini CLI is already installed locally and configured by the user or the calling environment.

## Design Principles

- Keep the delegated task narrow.
- Prefer compact, machine-readable output when useful.
- Treat Gemini output as advisory until it has been verified locally.
- Prefer Gemini for artifact-heavy browser work when that would otherwise bloat Codex context.

## Best Fit

This skill works best when the calling agent already understands the surrounding codebase and only wants to offload one bounded subtask, especially a review, diagnosis, browser audit, trace analysis, screenshot capture, or DOM extraction.
