# Stage 09 — Component & technical architecture

**Depends on:** `06-contracts`, `07-lofi`, `08-hifi` · **Produces:** `09-architecture.md`

Where the design becomes a buildable structure. The central question — one
component with variants, or two separate components — can only be answered now,
with every screen and every state visible at once.

## What to do

1. **Inventory components across all screens** and mark each global (shared),
   feature-scoped, or page-local. Count the usages; a component used once is
   page-local until proven otherwise.
2. **Decide variants vs separate components** for every pair that looks similar.
   The rule: **variants when they differ in appearance, separate components when
   they differ in behaviour or data shape.** Two cards that render the same
   fields with a different border are one component; two cards where one is
   clickable and fetches on hover are two. Getting this wrong in the "one
   component" direction produces the prop-explosion component everyone dreads.
3. **Draw the state boundaries.** What's server state (cached, refetched), what's
   URL state (filters, tabs, pagination — should almost always be URL state),
   what's local component state, what's genuinely global client state. Most
   over-engineered front ends are the result of skipping this.
4. **Directory structure** — concrete, matching what's already in the repo if
   there is one. Where do shared components live, where does feature code live,
   where do types from the contracts go.
5. **Server-side structure** — layers, where business rules live, where the
   invariants from stage 01 are enforced, how permissions are checked in one
   place rather than sprinkled.
6. **Write ADRs for anything contested** — one short record per decision with
   the alternatives and why they lost. Framework choice, state library, auth
   approach, monolith vs services, rendering strategy.
7. **Name the risky parts.** The one or two areas most likely to need rework, so
   the build plan can spike them early.

## Artifact template

~~~markdown
---
phase: 09-architecture
track: <full|compact>
status: draft
depends_on: [06-contracts, 07-lofi, 08-hifi]
updated: <date +%F>
---

# Architecture — <project>

## Component inventory
| Component | Scope | Used on | Variants | Notes |
|-----------|-------|---------|----------|-------|
| `StatusPill` | global | 6 screens | tone × 5 | pure display |
| `TaskCard` | feature | project detail | — | separate from `TaskRow`: different interaction |

## Variant decisions
| Pair | Decision | Why |
|------|----------|-----|

## State boundaries
| Kind | Holds | Tool |
|------|-------|------|
| Server | projects, tasks | <query lib>, 30s stale |
| URL | filters, tab, page | search params |
| Local | form drafts, open menus | component state |
| Global client | current org, theme | <context/store> |

## Directory structure
```
<tree>
```

## Server structure
<Layers, where invariants are enforced, where permission checks live.>

## ADRs
### ADR-01 — <decision>
**Chose:** … · **Over:** … · **Because:** … · **Costs us:** …

## Risky areas
| Area | Risk | Mitigation / spike first |
|------|------|-------------------------|

## Assumptions & open questions
~~~

## Gate

*Is any component about to become a prop-explosion, and is any state in the
wrong place?*

Then propose stage 10 (acceptance).
