# Stage 02 — Actors & use cases

**Depends on:** `00-brief`, `01-domain-model` · **Produces:** `02-use-cases.md`

Who does what, under what conditions, and what happens when it goes wrong. This
is the stage that determines the data model's access patterns, so it comes
*before* schema design, not after.

## What to do

1. **List every actor** — including the non-human ones. Scheduled jobs, webhooks
   from integrations, and admin/support staff are actors, and they're the ones
   teams forget until late.
2. **Build the permissions matrix** — actors down the side, domain entities
   across the top, CRUD in the cells. Note where permission is per-record rather
   than per-type ("edit own, view team's"). This matrix is what stage 05 and 06
   turn into row-level rules and auth checks.
3. **Write the use cases.** One per meaningful thing an actor can accomplish —
   not one per button. For each: trigger, preconditions, main flow, and
   **failure modes**.
4. **The failure modes are the point.** For every use case ask: what if it's
   already been done? What if two people do it at once? What if the actor loses
   permission halfway? What if the external system is down? What if the data is
   in an unexpected lifecycle state? Skipping this is what makes plans look
   complete and build twice as slowly as estimated.
5. **Cross-check against stage 01.** Every lifecycle transition should be caused
   by some use case. A transition nothing triggers is either a missing use case
   or a state that doesn't exist. Say which.

## Artifact template

```markdown
---
phase: 02-use-cases
track: <full|compact>
status: draft
depends_on: [00-brief, 01-domain-model]
updated: <date +%F>
---

# Use cases — <project>

## Actors
| Actor | Human? | Description |
|-------|--------|-------------|
| Scheduler | no | nightly expiry of unclaimed requests |

## Permissions matrix
| | Project | Task | Comment |
|--|---------|------|---------|
| Owner | CRUD | CRUD | CRUD |
| Member | R | CRU (own) | CRUD (own) |

Per-record rules: <e.g. "Member can edit a Task only while it is `open` and
assigned to them.">

## Use cases

### UC-01 — <Actor> <does thing>
- **Trigger:**
- **Preconditions:**
- **Main flow:** 1. … 2. … 3. …
- **Result:** <what changed, which lifecycle transition fired>
- **Failure modes:**
  | Situation | Behaviour |
  |-----------|-----------|

## Lifecycle coverage check
| Transition (from 01) | Caused by | Gap? |
|---------------------|-----------|------|

## Assumptions & open questions
```

## Gate

*Any actor missing? Any failure path we're pretending won't happen?*

Then propose stage 03 (scope & slicing).
