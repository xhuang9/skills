---
name: gemini-delegate
description: Use when the user wants to delegate a scoped subtask to the locally installed Gemini CLI or spend Gemini Code Assist / Google One AI Pro quota from the terminal, especially for small read-only investigations, summaries, MCP-assisted diagnostics, or Chrome debug tasks. Prefer non-interactive `gemini -p` runs and use `scripts/check_usage.mjs` instead of the interactive `/usage` panel.
---

# Gemini Delegate

Use this skill to hand a narrow task to the user's local Gemini CLI and fold the result back into the current task. Keep the delegated task small, explicit, and easy to verify.

## When To Use

- The user explicitly asks to use Gemini or Gemini CLI.
- The task is a focused summary, extraction, review, diagnosis, or small implementation with bounded context.
- The user wants to consume Gemini Code Assist or Google One AI Pro quota instead of doing the work in Codex.
- The task may benefit from Gemini's local project config, `GEMINI.md`, hooks, skills, or MCP servers already configured in the target workspace.
- The task can be described as a compact prompt and the expected output is short enough to review locally.

## When Not To Use

- Codex can handle the work directly without extra latency or quota burn.
- The task depends on Gemini's interactive TUI panels such as `/usage`, `/stats`, or manual auth prompts.
- The task needs wide repo exploration, long architectural context, or a long transcript back from Gemini.
- The delegated task would require broad write access without tight file or scope limits.
- Gemini CLI auth is unavailable or `scripts/check_usage.mjs` returns `skip`.

## Invoke Policy

Prefer delegating only when all of the following are true:

- The prompt can stay under roughly 12k characters.
- The relevant context is already known and can be named precisely.
- The expected Gemini result can stay under roughly 2k characters or a compact JSON payload.
- The user would plausibly benefit from using their Gemini quota for this subtask.

Good candidates:

- Review a scoped diff or a named file set.
- Summarize a bounded document or command output.
- Ask Gemini to inspect a trusted workspace that already exposes MCP tools.
- Use Gemini for Chrome or DevTools diagnostics when the target project already has the relevant MCP server configured.
- Use Gemini for browser-side artifact generation such as Lighthouse reports, screenshots, performance traces, and DOM or HTML extraction when a Chrome DevTools MCP server is configured.

Avoid auto-delegation when any of the following are true:

- You would need to paste broad repo context or conversation history.
- The task requires large edits across many files.
- The prompt would need many attachments or many directories.
- The expected output would be long enough that Codex loses the token savings.

## Usage Gate

Run [`scripts/check_usage.mjs`](./scripts/check_usage.mjs) before delegating.

What it does:

- Loads Gemini CLI's own config and auth stack.
- Calls `refreshAuth(...)`, `refreshUserQuota()`, and `refreshAvailableCredits()`.
- Prints clean JSON with the detected plan, Google AI credits, and per-model quota fractions.
- Returns a simple gate decision:
  - `delegate`
  - `confirm`
  - `skip`

Exit codes:

- `0` -> `delegate`
- `10` -> `confirm`
- `20` -> `skip`
- `30` -> internal error

Interpretation:

- `delegate`: quota looks healthy for the target model.
- `confirm`: quota is low, the target model is unclear, or usage info is incomplete. Ask the user before spending Gemini quota.
- `skip`: auth failed or quota is effectively unavailable. Do not delegate.

Important constraints:

- This is not the interactive `/usage` panel.
- The script reports model request quota fractions from Gemini's internal quota API, which is the stable interface available to us in non-interactive runs.
- Some accounts expose `remainingFraction` without `remainingAmount`, so percentage and reset time are the useful signals.

## Workflow

1. Verify Gemini CLI availability if it has not already been checked in this thread.
   - `which gemini`
   - `gemini --version`
2. Run the usage gate.
   - `node ~/.codex/skills/gemini-delegate/scripts/check_usage.mjs --cwd /path/to/project`
3. If the result is `skip`, continue in Codex and do not ask the user to spend Gemini quota.
4. If the result is `confirm`, ask the user to confirm using Gemini for this task.
5. Draft a narrow prompt with:
   - the exact objective
   - the allowed scope
   - the required output shape
   - explicit limits on editing or tool use
   - exact files or directories when relevant
6. Prefer non-interactive execution with [`scripts/delegate.sh`](./scripts/delegate.sh).
7. For real Gemini calls, use `functions.exec_command` with `sandbox_permissions="require_escalated"` because Gemini CLI needs external network access.
8. Summarize Gemini's result for the user instead of pasting a long raw transcript.

## Prompt Rules

- Name the exact files, folders, or excerpts Gemini should consider.
- Ask for a fixed output format when useful, such as bullets, JSON, or a checklist.
- State what Gemini must not do.
- Keep the delegated output intentionally short.
- Treat Gemini output as advisory until you verify it locally.

## Chrome And MCP Notes

- Run Gemini from the exact trusted project folder that owns the MCP configuration.
- If the task needs project MCP tools such as Chrome DevTools, pass them explicitly through the wrapper.
- Keep MCP tasks read-only unless the user asked for edits.
- Ask Gemini to report which MCP servers or tools it actually used.
- Prefer delegating browser workflows to Gemini when the task is primarily page inspection rather than Codex-side code changes.
- Good Chrome MCP delegation targets:
  - page screenshots
  - Lighthouse or accessibility audits
  - performance traces and load-metric summaries
  - console or network inspection
  - raw HTML extraction for a specific section or selector

## Gate Script

Recommended usage:

```bash
node ~/.codex/skills/gemini-delegate/scripts/check_usage.mjs \
  --cwd ~/project
```

Target a specific model:

```bash
node ~/.codex/skills/gemini-delegate/scripts/check_usage.mjs \
  --cwd ~/project \
  --model gemini-3.1-pro-preview
```

## Wrapper Script

Use [`scripts/delegate.sh`](./scripts/delegate.sh) for common non-interactive runs.

Supported options:

- `--model <name>`
- `--cwd <dir>`
- `--output text|json|stream-json`
- `--approval-mode <mode>`
- `--allowed-mcp-server <name>` (repeatable)
- `--include-directory <dir>` (repeatable)
- `--extension <name>` (repeatable)
- `--prompt-file <path>`

Prompt input order:

1. `--prompt-file`
2. trailing arguments after `--`
3. stdin

## Examples

Review a scoped task:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  -- "Review src/app.ts for two likely regression risks. Output 3 bullets max."
```

Return JSON:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  --output json \
  -- "List the top 3 risks in package.json as JSON with keys title and reason."
```

Allow a Chrome MCP server:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  --allowed-mcp-server chrome-devtools \
  -- "Use the available Chrome tooling to inspect the current page and summarize console errors."
```

Run a performance trace and save artifacts:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  --allowed-mcp-server chrome-devtools \
  -- "Use Chrome DevTools MCP to trace page-load performance for http://localhost:3000/ and save the trace plus a concise summary in the specified output folder."
```

Extract raw HTML for a section:

```bash
bash ~/.codex/skills/gemini-delegate/scripts/delegate.sh \
  --cwd ~/project \
  --allowed-mcp-server chrome-devtools \
  -- "Use Chrome DevTools MCP to find the section titled Simple Pricing and return its raw outerHTML."
```

## Limits

- `gemini -p "/usage"` does not return the interactive usage panel as plain output.
- The stable non-interactive usage path is the internal quota API accessed by `scripts/check_usage.mjs`.
- Gemini CLI may load local `GEMINI.md`, hooks, skills, and MCP config from the current workspace, so use the exact intended `--cwd`.
- If the wrapper is too restrictive, call `gemini` directly with explicit flags.
