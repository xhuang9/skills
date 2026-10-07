# Stage 08 — Hi-fi

**Depends on:** `07-lofi` · **Produces:** `08-hifi.md`

Visual direction and the token set. Deliberately *after* the state inventory:
designing the happy path first and retrofitting the eleven other states is how
you end up with a beautiful screen that looks unfinished the moment real data
hits it.

## What to do

1. **Check for an existing design system first.** A brand kit, a Figma library,
   an existing app, a component library already in the repo. If one exists, this
   stage is mostly *documenting the constraint*, not inventing a look. Note it
   and move fast.
2. **Decide the tokens** — colour (including semantic roles: danger, warning,
   success, muted), type scale, spacing scale, radii, shadows, motion timings.
   Concrete values, not adjectives.
3. **Design the states that matter most**, not just the full one. An empty
   state, an error, and a dense/overloaded view will tell you more about whether
   the direction works than a perfect hero screenshot.
4. **Data density is the real decision** in software UI. Pick a position —
   spacious and calm, or dense and information-rich — and apply it consistently.
   Most internal tools should be denser than the default instinct.
5. **Note the interaction states** for every interactive element: default,
   hover, focus-visible, active, disabled, loading. Focus-visible is not
   optional.
6. **Accessibility as a constraint, not a pass:** contrast ratios on the actual
   token pairs, target sizes, and never colour alone to convey status. Check it
   now, while changing a token is free.
7. If Figma is in play, use the `figma` / `figma-implement-design` skills rather
   than describing designs in prose here — this artifact then records decisions
   and links to nodes.

## Artifact template

```markdown
---
phase: 08-hifi
track: <full|compact>
status: draft
depends_on: [07-lofi]
updated: <date +%F>
---

# Hi-fi — <project>

## Basis
<Existing design system / brand kit / from scratch. Link.>

## Direction
<2–3 sentences. What it should feel like and why that suits these users.
Density position stated explicitly.>

## Tokens
| Token | Value | Used for |
|-------|-------|----------|
| `--color-surface` | #FFFFFF | page background |
| `--color-danger` | #B42318 | destructive actions, error text |

Type scale: … · Spacing scale: … · Radii: … · Motion: …

## Contrast check
| Pair | Ratio | Passes |
|------|-------|--------|

## Interaction states
| Element | default / hover / focus-visible / active / disabled / loading |
|---------|-------------------------------------------------------------|

## Designed screens
| Screen | States designed | Link |
|--------|----------------|------|

## Assumptions & open questions
```

## Gate

*Does it hold up in the empty and error states, and does every token pair pass
contrast?*

Then propose stage 09 (architecture).
