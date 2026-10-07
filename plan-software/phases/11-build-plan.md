# Stage 11 — Build plan

**Depends on:** `03-scope`, `05-data-model`, `06-contracts`, `10-acceptance` · **Produces:** `11-build-plan.md`

The last planning stage. Turns everything above into an ordered list of
**vertical slices** — each one a thin cut through data, server and UI that a
person could demo. Not a list of layers.

## What to do

1. **Slice vertically, not horizontally.** "All the database tables" is not a
   slice; "a user can create a project and see it in the list" is. Horizontal
   layering hides integration problems until the end, which is exactly when
   they're most expensive.
2. **Slice 0 is the walking skeleton** — the thinnest path from UI to database
   and back, deployed. Auth, one route, one query, one deploy. Everything after
   it is comparatively predictable; before it, nothing is.
3. **Order by dependency and risk.** Anything flagged risky in stage 09, and any
   external integration, comes early — a spike before you've built around its
   assumptions costs a day; after, it costs a rewrite.
4. **Each slice states:** what it delivers, what it depends on, which
   acceptance criteria it satisfies, and what's demoable at the end. If nothing
   is demoable, it's the wrong slice boundary.
5. **Note what's parallelisable** — the contracts from stage 06 are what let
   front and back proceed at once. Say which slices can run concurrently and
   where they must rejoin.
6. **Don't estimate in hours unless asked.** Relative size (S/M/L) and ordering
   are what's useful and what survives contact with reality.
7. **List the setup work explicitly** — repo, CI, environments, seed data, error
   tracking. It's real work and it always gets left out of plans.

## Artifact template

~~~markdown
---
phase: 11-build-plan
track: <full|compact>
status: draft
depends_on: [03-scope, 05-data-model, 06-contracts, 10-acceptance]
updated: <date +%F>
---

# Build plan — <project>

## Setup
- [ ] repo, CI, lint/format
- [ ] environments + secrets
- [ ] seed data
- [ ] error tracking

## Slices
### 0 — Walking skeleton  · S
**Delivers:** login → empty project list → deployed to staging
**Depends on:** setup
**Satisfies:** —
**Demoable:** log in on staging and see your (empty) project list

### 1 — Create and list projects · M
**Delivers:** `projects` table, `POST /projects`, `GET /projects`, create form, list screen
**Depends on:** slice 0
**Satisfies:** UC-01 criteria 1–4
**Demoable:** create a project, see it appear, reload and it persists

<Repeat.>

## Dependency order
```
0 → 1 → 2 ─┬→ 4
           └→ 5 → 6
```

## Parallel tracks
| Track | Slices | Rejoins at |
|-------|--------|-----------|

## Spike first
| Unknown | Why risky | Timebox |
|---------|----------|---------|

## Assumptions & open questions
~~~

## Gate

*Is every slice independently demoable, and does the riskiest unknown get
touched early rather than last?*

## Ending the ladder

This is the final stage. Print the full state table, list every open question
still outstanding across all artifacts (they don't disappear because planning
finished), and tell the user the plan is ready to build from — pointing at the
artifacts directory. Then stop. **Do not start implementing** unless the user
asks; that's a separate decision from finishing the plan.
