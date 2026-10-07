# Artifact format

Every stage writes one markdown file to the artifacts directory, named
`NN-slug.md` matching its stage number in the table of contents.

## Frontmatter contract

The router reads only this block to build the state table, so it must be exact.

```yaml
---
phase: 05-data-model
track: full          # full | compact
status: draft        # draft | reviewed | skipped
depends_on: [02-use-cases, 03-scope]
updated: 2026-07-26  # get with `date +%F` — never guess
---
```

- `status: draft` — written but not signed off. The default on write.
- `status: reviewed` — the user has said it's good. Only the router sets this,
  after the user confirms.
- `status: skipped` — deliberately not run (e.g. 07–09 on the compact track).
  Still write the file, with a one-line reason in the body, so the state table
  shows the decision rather than a gap.

## Staleness

An artifact is stale when any file in its `depends_on` has a later `updated`
date. Report it; never quietly build on a stale artifact.

## Body conventions

- Lead with the decisions, not the reasoning. This is a reference document that
  later stages read, not an essay.
- Tables over prose wherever the content is a list of things with attributes.
- Use the exact domain vocabulary fixed in `01-domain-model.md`. If you need a
  word that isn't in the glossary, that's a signal to go add it there, not to
  invent a synonym here.
- Every artifact ends with:

```markdown
## Assumptions & open questions

**Assumed:**
- <thing you decided without being told, and what it would cost to be wrong>

**Needs an answer:**
- <question> — blocks: <which later stage>
```

An empty section is a red flag, not a clean bill of health. If a stage genuinely
had none, say so explicitly and say why.

## Writing style for artifacts

Write for a competent colleague joining in three weeks. No preamble, no
restating the brief, no "this document will…". Cut anything that would still be
true of a different project.
