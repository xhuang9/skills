# Stage 04 — Screen map / IA

**Depends on:** `02-use-cases`, `03-scope` · **Produces:** `04-screen-map.md`

The information architecture stage. Same idea as IA on a marketing site — what
pages exist and what each is for — but here it is *downstream* of use cases
rather than the organising principle. On a marketing site content drives
structure; in software, tasks do.

## What to do

1. **List the screens/routes** with real URL patterns, including the parameterised
   ones (`/projects/:id/tasks/:taskId`).
2. **Give each screen one job** in a sentence. If a screen needs "and" to
   describe it, consider whether it's two screens or a screen with tabs — decide
   which, don't leave it ambiguous.
3. **Build the screen → use case matrix.** Every use case from stage 02 that's
   in the MVP cut must appear on at least one screen. Orphaned use cases are the
   whole reason this matrix exists — they're the features that get discovered
   missing during build.
4. **Map navigation** — what's in primary nav, what's nested, what's reachable
   only from a link inside another screen. Note the entry points: where does a
   user land after login, after an email link, after completing something?
5. **Mark the permission-dependent bits.** Which screens or nav items exist only
   for certain actors, per the permissions matrix. This shapes the routing layer.
6. **Note modals and non-screen surfaces** — dialogs, drawers, toasts, emails.
   An email with a deep link is part of the IA.

## Artifact template

```markdown
---
phase: 04-screen-map
track: <full|compact>
status: draft
depends_on: [02-use-cases, 03-scope]
updated: <date +%F>
---

# Screen map — <project>

## Routes
| Route | Screen | Its job | Visible to |
|-------|--------|---------|------------|
| `/projects/:id` | Project detail | see status and act on tasks | Owner, Member |

## Navigation
- **Primary nav:** …
- **Nested / contextual:** …
- **Entry points:** after login → …; from notification email → …

## Screen → use case matrix
| Use case | Screen(s) | 
|----------|-----------|
| UC-01 | `/projects/new` |

**Orphaned use cases:** <none | list them — these need a home before build>

## Modals & non-screen surfaces
| Surface | Triggered from | Purpose |
|---------|---------------|---------|

## Assumptions & open questions
```

## Gate

*Does every in-scope use case have a home, and does any screen have more than
one job?*

Then propose stage 05 (data model) — or 06 (contracts) in the same turn if
you're on the compact track and 05 is already written.
