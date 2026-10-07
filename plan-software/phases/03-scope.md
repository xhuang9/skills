# Stage 03 — Scope & slicing

**Depends on:** `00-brief`, `02-use-cases` · **Produces:** `03-scope.md`

Turn use cases into a decided MVP. This is the only stage where scope is
negotiable — after this, every later stage assumes the cut is settled, and
reopening it invalidates them.

## What to do

1. **Group use cases into features.** A feature is a shippable unit a user would
   name; a use case is a thing they do. Several use cases usually make one
   feature.
2. **Prioritise honestly.** Must / should / later. The test for "must": if this
   were missing on launch day, would the product fail at its stated success
   criteria from the brief? If not, it isn't a must.
3. **Walk `references/cross-cutting-checklist.md` in full.** Every item gets a
   decision or an explicit "not needed, because…". Auth model, roles, tenancy,
   audit, soft delete, background jobs, notifications, file storage,
   integrations, environments, scale, compliance. These aren't features, they're
   multipliers on every feature, and they must be decided before the data model.
4. **Write the out-of-scope list.** Take the brief's non-goals, add everything
   that came up during 01 and 02 and got deferred. Each with one line of why.
   This list is the most useful artifact of the stage.
5. **Size the cut against the brief's constraints.** If the must-have list
   clearly doesn't fit the deadline and team, say so now with a specific
   suggestion of what to drop. Say it plainly — this is the moment where it's
   cheap.

## Artifact template

```markdown
---
phase: 03-scope
track: <full|compact>
status: draft
depends_on: [00-brief, 02-use-cases]
updated: <date +%F>
---

# Scope — <project>

## Features
| Feature | Use cases | Priority | Why this priority |
|---------|-----------|----------|-------------------|

## MVP cut
<The must-haves as a single paragraph someone could read aloud in a meeting.>

## Cross-cutting decisions
| Concern | Decision | Affects |
|---------|----------|---------|
| Tenancy | single org, no partitioning | data model — revisit if we sell to a 2nd customer |
| Audit trail | not needed for MVP | — |
| Soft delete | yes, on Project and Task only | data model, all list queries |
<One row per checklist item. "Not needed" is a valid decision; silence is not.>

## Out of scope
| Not doing | Why | Revisit when |
|-----------|-----|--------------|

## Fit against constraints
<Does the must-have list fit the deadline and team from the brief? If not, what
specifically should move to `later`.>

## Assumptions & open questions
```

## Gate

*Is the MVP cut defensible, and did any cross-cutting item get quietly skipped?*

Then propose the next stage — 04 (screen map) on the full track, 05 (data model)
in the same turn on compact.
