# Stage 01 — Domain model

**Depends on:** `00-brief` · **Produces:** `01-domain-model.md`

The vocabulary layer. Get the nouns and their lifecycles right once and every
later stage — schema, API, screens, code — inherits them for free. Get them
wrong and you rename things for the rest of the project.

This is the software equivalent of keyword research on a marketing site: it's
not decoration, it's the spine everything else hangs off.

## What to do

1. **Extract the nouns** from the brief and from how the user actually talks.
   Use *their* word, not the generic one — if the business says "matter", don't
   call it "case". Note synonyms you're rejecting so nobody reintroduces them.
2. **Define each concept in one sentence** that distinguishes it from its
   neighbours. If you can't tell two concepts apart in a sentence, they're
   probably one concept, or you're missing the thing that separates them.
3. **Map relationships** with real cardinality — and check each one for whether
   it's *actually* one-to-many or secretly many-to-many over time. ("A project has
   one owner" — can ownership be transferred? Do you need the history?)
4. **Write the lifecycle of every entity that has one.** States, allowed
   transitions, who or what triggers each. This is the highest-value part of the
   stage: most real bugs in a system are illegal state transitions nobody wrote
   down. If an entity is just data with no lifecycle, say so explicitly.
5. **Write the invariants** — the rules that must be true at all times. "An
   invoice cannot be edited after it's been sent." These become validation,
   constraints and tests later.
6. Flag anything you inferred rather than were told. Domain facts are the most
   dangerous thing to guess at.

## Artifact template

```markdown
---
phase: 01-domain-model
track: <full|compact>
status: draft
depends_on: [00-brief]
updated: <date +%F>
---

# Domain model — <project>

## Glossary
| Term | Means | Not to be confused with | Rejected synonyms |
|------|-------|------------------------|-------------------|

## Relationships
| From | Relationship | To | Notes |
|------|-------------|-----|-------|
| Project | has many | Task | ordered; tasks can't move between projects |

## Lifecycles
### <Entity>
States: `draft → submitted → approved | rejected → archived`

| From | To | Trigger | Who | Guard |
|------|-----|---------|-----|-------|

<Repeat per entity. For entities with no lifecycle: "**Tag** — no lifecycle,
created and deleted only.">

## Invariants
- <rule that must always hold>

## Assumptions & open questions
```

## Gate

*Is this the vocabulary the business actually uses, and is any lifecycle state
missing?*

Then propose stage 02 (use cases). On the compact track, run 02 in the same turn
and write both artifacts.
