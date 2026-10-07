# Stage 10 — Acceptance criteria

**Depends on:** `02-use-cases`, `03-scope` · **Produces:** `10-acceptance.md`

The definition of done, written before the build rather than reconstructed
after it. This is what makes the build stage verifiable instead of a matter of
opinion.

## What to do

1. **Criteria per in-scope use case**, phrased as observable behaviour someone
   could check without reading the code. Given / when / then works well; so does
   a plain checkable sentence. "Submitting twice returns a state conflict and
   does not create a second record" is checkable. "Submission works properly" is
   not.
2. **Cover the failure modes from stage 02, not just the happy path.** Every
   failure row in a use case deserves a criterion — those are the ones that go
   untested otherwise.
3. **Cover the invariants from stage 01.** Each one should have a criterion
   proving it can't be violated through the UI or the API.
4. **Assign a test layer to each criterion:**
   - **unit** — pure logic, state transition rules, validation
   - **integration** — endpoint + database, permission checks, constraints
   - **e2e** — only the few critical user journeys; expensive and brittle, so
     spend them where failure is worst
   - **manual** — legitimately, for things not worth automating; say so
     explicitly rather than pretending
5. **Name the critical journeys** — the two or three flows that, if broken,
   mean the product is down. These get e2e coverage and nothing else needs to.
6. **Note what you're deliberately not testing** and why. An honest gap beats a
   fake coverage claim.

## Artifact template

```markdown
---
phase: 10-acceptance
track: <full|compact>
status: draft
depends_on: [02-use-cases, 03-scope]
updated: <date +%F>
---

# Acceptance — <project>

## Criteria
### UC-04 — Member submits a project
| # | Criterion | Layer |
|---|-----------|-------|
| 1 | A `draft` project with ≥1 task can be submitted; status becomes `submitted` and `submitted_at` is set | integration |
| 2 | Submitting an already-`submitted` project returns `state_conflict` and creates nothing | integration |
| 3 | A Member not assigned to the project gets `forbidden` | integration |
| 4 | The submit button is disabled while the request is in flight | unit |

<Repeat per use case.>

## Invariant coverage
| Invariant (from 01) | Covered by | Layer |
|--------------------|-----------|-------|

## Critical journeys (e2e)
1. <journey> — why it's critical

## Not tested, deliberately
| Area | Why | Risk accepted |
|------|-----|---------------|

## Assumptions & open questions
```

## Gate

*Is every failure mode and every invariant covered, and is the e2e list short
enough to actually stay green?*

Then propose stage 11 (build plan). On the compact track, run 11 in the same
turn.
