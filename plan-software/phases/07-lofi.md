# Stage 07 — Lo-fi

**Depends on:** `04-screen-map`, `06-contracts` · **Produces:** `07-lofi.md`

Layout and states, no visual design. The valuable output here isn't the
wireframe — it's the **state inventory**. Software screens spend a lot of their
life not in the happy path, and the states nobody drew are the ones that ship
broken.

## What to do

1. **Per screen: what's on it and roughly where.** Regions, hierarchy, primary
   action. ASCII blocks or a described grid are fine; the point is agreement on
   content and priority, not pixels.
2. **Enumerate every state for every screen:**
   - empty (never had data) — different from *filtered to nothing*
   - loading (first load vs refetch vs optimistic)
   - partial (some data, some still loading)
   - error (request failed, and can they retry?)
   - permission-denied (do they see nothing, or a locked view?)
   - each lifecycle state from stage 01 that changes what's rendered
   - long content / very long strings / many rows
3. **Empty states carry the onboarding.** For a new user, the empty state *is*
   the product. Say what each one tells the user to do.
4. **Forms:** fields, validation timing (blur vs submit), what's inline vs
   summary, what happens on partial failure, and whether progress survives a
   refresh.
5. **Responsive intent** — what changes on small screens. Which tables become
   cards, what collapses, what's hidden.
6. Cross-check each screen against its stage-06 contract: everything rendered
   must be in a response, and every meaningful response field should be used or
   explicitly noted as unused.

## Artifact template

~~~markdown
---
phase: 07-lofi
track: <full|compact>
status: draft
depends_on: [04-screen-map, 06-contracts]
updated: <date +%F>
---

# Lo-fi — <project>

## <Screen name> — `/route`
**Job:** <from stage 04> · **Primary action:** <the one thing>

**Layout**
```
┌──────────────────────────────┐
│ header: title · status pill  │
├──────────────┬───────────────┤
│ task list    │ detail panel  │
└──────────────┴───────────────┘
```

**States**
| State | What the user sees | Actions available |
|-------|-------------------|-------------------|
| empty | "No tasks yet" + Create button | Create |
| loading | skeleton rows | — |
| error | inline banner + Retry | Retry |
| denied | read-only view, no actions | — |
| status=archived | banner, all actions disabled | Unarchive (Owner) |

**Responsive:** <what changes under ~768px>

**Data used:** <fields from which contract response>

<Repeat per screen.>

## Assumptions & open questions
~~~

## Gate

*Which state is missing — and what does a brand-new user with no data see?*

Then propose stage 08 (hi-fi).
