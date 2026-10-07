---
name: plan-software
description: Staged planning ladder for building software. Runs a project through brief, domain model, use cases, scope, screen map, data model, contracts, design, architecture, acceptance and build plan — one stage per turn, writing a reviewable artifact for each. Use when planning, speccing or scoping software to be built (an app, product, feature or system) rather than jumping straight to code. Not for marketing sites.
argument-hint: "[project or feature to plan | status | continue]"
---

# plan-software — staged planning ladder

Planning a real system in one turn produces a plausible document that nobody can
correct, because every later decision has already been made on top of an
unreviewed earlier one. This skill runs **one stage per turn**, writes each
stage's output to a file, and asks before moving on.

**This file is a table of contents and a router.** It does not contain the stage
instructions — each stage lives in its own file under `phases/`. Read only the
stage file you are about to run.

---

## 1. Resolve the artifacts directory

Do this first, every time.

- **Default:** `<project-root>/.claude/plan-software/artifacts/`, where
  `<project-root>` is the git root of the current working directory, or the cwd
  if it is not a repo.
- **Override:** if the user names a path, use it verbatim.
- **Hard guard:** the resolved path must NEVER be inside `~/.claude/skills/` or
  be `~/.claude/plan-software/`. Artifacts belong to the project being planned,
  not to the skill. If the cwd is `~/.claude` itself, stop and ask the user which
  project this plan is for.

Create the directory if missing. Announce the resolved path once per session.

## 2. Read the state before doing anything

List the artifacts directory and read the frontmatter of every `*.md` in it
(frontmatter contract: `references/artifact-format.md`). Build the state table:

```
Track: compact          Artifacts: ./.claude/plan-software/artifacts/
✓ 00  Brief             reviewed
✓ 01  Domain model      reviewed
▶ 02  Use cases         draft        ← resume here
·  03  Scope            —
```

Legend: `✓` reviewed · `▶` draft or in progress · `·` not started · `⊘` skipped
· `⚠` stale.

**Staleness:** an artifact is stale if any artifact in its `depends_on` list has
a later `updated` date. Mark it `⚠` and say so — do not silently build on it.

If the user said `status`, print the table and stop there.

## 3. Pick the track (first run only)

Ask once, at the end of stage 00, then record `track:` in every artifact.

- **compact** — under roughly two weeks of build, one or two people, no novel
  domain. Five turns.
- **full** — multi-month, multiple actors and roles, real permission or state
  complexity, or a team that has to split the work. Twelve turns.

Artifact numbers are the same in both tracks; compact just runs fewer stages and
groups them.

## 4. Table of contents

| # | Stage | Phase file | Produces |
|---|-------|-----------|----------|
| 00 | Brief | `phases/00-brief.md` | problem, users, constraints, non-goals |
| 01 | Domain model | `phases/01-domain-model.md` | glossary, relationships, entity lifecycles |
| 02 | Use cases | `phases/02-use-cases.md` | actors, permissions matrix, use cases with failure modes |
| 03 | Scope & slicing | `phases/03-scope.md` | prioritised features, MVP cut, out-of-scope list |
| 04 | Screen map | `phases/04-screen-map.md` | routes, navigation, screen → use case matrix |
| 05 | Data model | `phases/05-data-model.md` | tables, cardinality, indexes, tenancy/audit decisions |
| 06 | Contracts | `phases/06-contracts.md` | endpoints/actions, payloads, error taxonomy, auth |
| 07 | Lo-fi | `phases/07-lofi.md` | wireframes, per-screen state inventory |
| 08 | Hi-fi | `phases/08-hifi.md` | visual direction, design tokens |
| 09 | Architecture | `phases/09-architecture.md` | global vs local components, state boundaries, ADRs |
| 10 | Acceptance | `phases/10-acceptance.md` | acceptance criteria per use case, test layer split |
| 11 | Build plan | `phases/11-build-plan.md` | vertical slices in dependency order |

**Compact track** runs these five turns:

| Turn | Stages | Note |
|------|--------|------|
| 1 | 00 | |
| 2 | 01 + 02 | two artifacts, one turn |
| 3 | 03 + 05 | |
| 4 | 04 + 06 | |
| 5 | 10 + 11 | |

07, 08 and 09 are written as `status: skipped` in compact. If the project turns
out to be UI-heavy, offer to add them back rather than assuming.

## 5. Run exactly one turn

1. Read the phase file(s) for this turn — **only** those.
2. Read the artifacts this stage depends on. Do not re-derive them.
3. Do the stage's work. Ask the user questions where the stage file says to; do
   not invent domain facts you could have asked about.
4. Write the artifact(s) to the artifacts directory as `NN-slug.md`, using the
   frontmatter contract and the template in the phase file.
5. Every artifact ends with an **Assumptions & open questions** section. If that
   section is empty you have almost certainly guessed at something — go find it.
6. Stop and propose the next stage (§6).

Never run two turns in one response, even if the first was quick.

## 6. Ending a turn

Close with a short summary of what the artifact decided, the open questions that
most need a human answer, and then the proposal:

> Written `02-use-cases.md`. Two open questions in there — the biggest is whether
> a reviewer can edit a submission or only reject it. Next up is **03 Scope &
> slicing**: turning these into an MVP cut plus an explicit out-of-scope list.
> Want me to continue, or review this one first?

Do not proceed until the user answers. When they mark a stage good, set
`status: reviewed` in its frontmatter before starting the next.

If the user asks to jump ahead past an unwritten stage, say what's missing and
what could go wrong, then do as they ask.

## 7. Amending an earlier stage

Rewrite that artifact, bump its `updated` date, then re-run the state table.
Everything downstream now shows `⚠ stale`. List what's stale and ask whether to
refresh those stages or leave them — do not auto-rewrite them.

## 8. References

- `references/artifact-format.md` — frontmatter contract and shared conventions
- `references/cross-cutting-checklist.md` — auth, roles, tenancy, jobs,
  notifications, audit, storage, integrations, environments. Applied at stage 03,
  re-checked at 05. These are what blow up plans in week six.
