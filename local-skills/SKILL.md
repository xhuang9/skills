---
name: local-skills
description: Capture an important, durable project rule as a project-local "guardrail skill" so future sessions reliably honour it. A skill's description is always loaded and auto-invokes the moment its keywords match — far more reliable than a rule buried in CLAUDE.md or a doc chunk that may never be opened. Use when the user says "remember this in the project", "never do this again", "don't do X in future sessions", "make this a project rule (not CLAUDE.md)", "this should affect future work / future sessions", or runs /local-skills. Also invoke when documenting knowledge that is a behavioural rule or guardrail (not mere reference) that must change how agents act in this repo. Also invoke when a guardrail skill points to a chunk that no longer exists or is marked expired (in docs-manifest.json) — to notify the user the skill needs updating.
argument-hint: "[optional] a short description of the rule to capture, or an existing <short>-<name> skill to extend"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(mkdir *), AskUserQuestion
---

# local-skills — generate project-local guardrail skills

This skill turns a durable behavioural rule into a **project-local skill** so that
future agents in this repo reliably honour it.

## Why a skill beats a doc for rules

A skill is loaded in two stages:

- Its **`description`** (one line) is **always** injected into every session's
  context. It is the trigger surface.
- Its **body** (`SKILL.md` and any sub-docs) loads **on demand**, only when the
  skill is invoked.

So a guardrail-as-skill is cheap when idle and loud when relevant: the
description auto-invokes the skill the moment its keywords match, and an invoked
skill's instructions carry more weight than a doc the agent was merely told
exists.

```
chunk doc        → agent learns it exists only IF it opens the section index   (often never)
CLAUDE.md line   → always loaded, but drowned among many other guardrails       (easy to miss)
guardrail SKILL  → always-on description trigger + on-demand body               ← use this for rules
```

Rules → guardrail skills. Reference knowledge → keep it in `.readme/` chunks.
Heavy-context, fixed-output **tasks** → a project-local **sub-agent** (see
*Skill vs sub-agent* below) — sometimes fronted by a thin trigger skill.

> Honest limit: auto-invoke is keyword-driven and probabilistic, not a hard
> gate. For "preference" rules (icons, tone, naming) this is the right weight.
> For "corrupts data if skipped" rules (e.g. migration markers) a real hook is
> still the only deterministic lock — note that to the user, don't pretend the
> skill guarantees it.

## How precedence works (read before touching the shim)

Claude Code resolves same-named skills as **Enterprise > Personal (global) >
Project (local)**. This skill's name (`local-skills`) is global, so when a
project also has a `local-skills` skill, **this global copy is the one that
runs** — the project copy is *shadowed* and never executes on its own.

Therefore the project-local `local-skills` file is **not an override**. It is a
**data/config file that this global skill reads** to discover the project's
shortname. This global skill is always the executor; it goes and finds the local
file to look up the shortname. Generated guardrail skills (`<short>-<name>`) have
unique names, so they are *not* shadowed and run normally as project skills.

## Skill vs sub-agent — choose the artifact first

Before writing a skill, decide what the durable thing actually is. There are three
artifacts, not one:

| The durable thing is… | Make it a… | Why |
|---|---|---|
| A **behavioural rule** that must change how the **main agent** acts on its own edits (never/always/must) | **guardrail skill** | The always-on description must steer the main agent; a sub-agent can't carry behaviour back. |
| **Reference knowledge** (how something works) | **`.readme/` chunk** | Not a rule; lives in the docs lifecycle. |
| A **heavy-context, fixed-output task** | **project-local sub-agent** (`.claude/agents/`), optionally fronted by a thin trigger skill | Runs in an isolated context, so its file reads / noisy command output / query dumps stay out of the main thread — only the result returns. |

**Create a sub-agent instead of (or behind) a skill when ALL of these hold:**

1. **Runtime context is heavy** — it reads many files, runs noisy commands (query
   dumps, ffmpeg, broad Explore sweeps) whose output you don't want lingering in the
   main thread.
2. **The output is a self-contained deliverable** — a file, a report, an answer; the
   intermediate junk isn't needed afterwards.
3. **It doesn't depend on the live conversation** — a fresh agent can do it from its
   inputs alone (an agent can't see the main thread's history).
4. **It is NOT a behavioural guardrail** — see the hard exclusion below.

**Never convert to a sub-agent (keep it a skill / CLAUDE.md / hook) when:**

- It's a **guardrail** that must change the main agent's *own* behaviour. A
  sub-agent's behaviour changes don't propagate back, and sub-agents receive skills
  as **names only** — descriptions stripped, no auto-invoke (see
  `~/.claude/chunks/subagent-skill-context.md`). Guardrails are also small and cheap,
  so there's nothing to save.
- It **depends on the current conversation** (e.g. "summarise what we just did") —
  the agent can't see it.

### The hybrid: thin trigger skill → delegates to the agent (preferred)

Agents do **not** auto-invoke on keywords; skills do. So don't *replace* a triggerable
skill with an agent — keep a **~10-line skill** as the trigger/router whose body just
delegates, and move the heavy process into the agent:

```
---
name: <skill-name>            # keep the SAME description + argument-hint so keyword
description: <unchanged>       # auto-invoke still fires
---
# delegate to the <short>-<name> agent
Spawn the `<short>-<name>` sub-agent via the Agent tool
(subagent_type: "<short>-<name>"), passing the user's input ($ARGUMENTS) as the task.
Relay its final summary; do not run the heavy steps inline.
```

A pure agent (no front skill) is fine when the work is only ever invoked deliberately
by the orchestrator, never by a user keyword.

### Authoring the agent

- **Location:** `<root>/.claude/agents/<short>-<name>.md` — **project-local**, never
  `~/.claude/agents/` (global), unless the user explicitly wants it global.
- **Frontmatter:** `name`, `description` (this is the orchestrator's selection
  surface — say when to use it), `model` (sonnet for mechanical / definitive-outcome
  work, opus for judgement-heavy work), and an optional minimal `tools` whitelist
  (omit `Write`/`Edit` for read-only investigation agents to enforce no-mutation).
- **Body:** the full task process (you can move a heavy skill body here verbatim).
  Because the agent starts fresh, restate the key environment facts it needs (paths,
  `.project-folder`, where the CLI/debug tools live). End with an explicit
  **"your final message IS the result returned to the main thread — make it a tight
  summary, not a transcript"** instruction.
- **Don't duplicate the rule back into CLAUDE.md**; the thin skill (or the agent's
  own description) is the trigger.

## Workflow

### 1. Resolve the workspace root and project shortname

- The **workspace root** is the current directory that contains `.claude/` and
  `CLAUDE.md`. All local skills live at `<root>/.claude/skills/`.
- The **shortname** is a 2–4 char project tag prefixed onto every generated
  skill (e.g. acme-app → `aa`, so skills are `aa-icon`, `aa-tone`, …).
- Read the project-local config file `<root>/.claude/skills/local-skills/SKILL.md`
  and extract its `shortname:` frontmatter field
  (`grep -m1 '^shortname:' <root>/.claude/skills/local-skills/SKILL.md`). If
  present, reuse it silently — do not re-ask.
- If the file or the field is missing, propose a shortname derived from the
  project (folder-name initials, or the `.project-folder` value), **ask the user
  to confirm or override** with `AskUserQuestion`, then run step 2 to persist it.

### 2. Bootstrap the local config shim (first run in a project only)

Write `<root>/.claude/skills/local-skills/SKILL.md` as a **read-only discovery /
config file** — not an override. It must contain:

- `name: local-skills` and the same `description` as this skill, so it still
  appears when browsing the project's skills. It will be shadowed at runtime —
  that is expected and fine; this global skill is the executor.
- a `shortname: <short>` frontmatter field — the machine-readable value this
  skill greps for on every future run.
- a short body noting the file is intentionally shadowed and exists only so the
  global `local-skills` skill can discover the shortname. Mirror the `handover`
  shim style in this repo.

Template:

    ---
    name: local-skills
    description: <copy this global skill's description verbatim>
    shortname: <short>
    allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(mkdir *), AskUserQuestion
    ---

    # local-skills (local config shim for <project>)

    Project shortname: **`<short>`** — generated guardrail skills go to
    `<root>/.claude/skills/<short>-<name>/`.

    Precedence is Enterprise > Personal (global) > Project (local), so this file is
    shadowed by the global skill and does not run. It exists so the global
    `~/.claude/skills/local-skills/SKILL.md` skill can read the shortname above.

### 3. Create or extend a guardrail skill

1. **Decide: new skill or extend an existing one.** List `<root>/.claude/skills/<short>-*`.
   If a related guardrail skill already owns this domain, **add a part to it**
   (step 4) instead of creating a near-duplicate.
2. **Ask the user for the name** (`AskUserQuestion`). Convention: the shortest
   clear English word, `<short>-` prefix, no ambiguity — `bl-icon`, `bl-tone`,
   `bl-migrate`. Never skip this; the user has asked to confirm every name.
3. **Write `<root>/.claude/skills/<short>-<name>/SKILL.md`** with:
   - `description:` = a tight trigger sentence. Front-load the domain keywords an
     agent would be working in when the rule applies (file types, component
     names, the action verb) **and** a one-clause summary of the rule itself, so
     the always-on description alone already states the guardrail. Be specific:
     vague descriptions don't auto-invoke reliably.
   - body = the actual rule: what's banned/required, why, and what to do instead.
4. If the rule mirrors an existing `.readme/` chunk, reference the chunk path —
   don't copy its full contents; keep the skill the authoritative trigger.

### 4. Hierarchy & context protection (large or multi-part rules)

A guardrail skill must not dump a wall of text into context every time it fires.
When a rule has several parts, **split the folder** like a mini section/chunk
structure:

```
<short>-style/
  SKILL.md      ← lean: trigger description + a "Parts" table (read X when Y)
  icons.md      ← full detail, read on demand
  buttons.md
  color.md
```

Rules:

- `SKILL.md` stays a **lean table of contents**. It lists each part as a one-line
  row: `| part file | what it covers | read when |`. Only `SKILL.md` loads on
  invoke; the agent then `Read`s only the part it needs.
- Put heavy detail (tables, long lists, code) in part files, never in `SKILL.md`.
- One part = one coherent sub-topic. If a single rule is small, skip the
  hierarchy and keep it inline in `SKILL.md`.

The goal is always: load the **correct** context, not all of it.

### 5. Don't duplicate the rule back into CLAUDE.md

The skill is now the trigger. Don't also paste the full rule into CLAUDE.md — at
most leave a one-line pointer if discoverability there genuinely helps. Avoiding
duplication keeps the rule single-sourced and the context lean.

### 6. Elevating many existing rules at once (bulk audit + context discipline)

When asked to sweep CLAUDE.md / sections / chunks for rules to turn into skills:

- **Classify first.** A behavioural RULE (never/always/must, with a real
  consequence if missed) becomes a skill; pure reference/explanation stays a doc.
  Search for intentional emphasis: `GUARDRAIL`, `NEVER`, `MUST`, "data loss",
  "breaks production", "silently". Most casual "should" hits are NOT guardrails.
- **GROUP, don't multiply.** Related rules that fire on the same kind of work
  share ONE skill with a broad trigger (e.g. all sync/data-integrity rules →
  one `<short>-sync`). Do NOT create one skill per rule — every skill adds an
  always-on description, so over-creation rebuilds the very context bloat you are
  trying to avoid.
- **Point, don't copy.** If the detail already lives in a chunk, the skill states
  the rule in one line and links the chunk. No duplication, no drift.
- **Be selective.** Skip low-severity, narrow, or already-covered rules (e.g. one
  an existing skill already enforces). Leave them as chunks. Fewer, sharper skills
  beat many vague ones — vague descriptions auto-invoke unreliably.
- **Keep critical sub-agent rules in CLAUDE.md too.** Sub-agents receive skills as
  names only — descriptions stripped, no auto-invoke (see
  `~/.claude/chunks/subagent-skill-context.md`). A rule that prevents data loss or
  production breakage and is acted on by delegated agents must stay in CLAUDE.md
  (or be enforced by a hook), not skill-only. Slim CLAUDE.md by moving recoverable
  *preference* rules to skills; keep the dangerous ones.

### 7. Skills POINT to chunks — they do not restate content

A guardrail skill is a stable **trigger + pointer**. The actual rule lives in a
`.readme` chunk (or doc), which the docs lifecycle (`/doc-task`, `/doc-update`,
`docs-manifest.json` expiry) keeps fresh. **Skills are NOT in that lifecycle**, so
any rule text restated inside a skill silently drifts from the chunk. So:

- The skill **body** lists chunk pointers; the **description** carries only the
  trigger (the work domain + stable keywords), not the rule's mechanics. Say
  "read the linked chunk (source of truth)", don't paraphrase the rule.
- This also keeps the always-on description short.

**Stale-pointer maintenance trigger:** if, while using or reading a guardrail
skill, you find a chunk it points to is **missing** (gone from disk) or **marked
expired** (flagged in `docs-manifest.json`), invoke this skill and **notify the
user** that the skill's pointer is stale — it needs re-pointing to the renamed /
replacement chunk, or the rule re-captured. Never silently rely on a dangling
pointer.

## Report

Tell the user: the skill path created/extended, its trigger keywords, and one
line on when it will auto-invoke.
