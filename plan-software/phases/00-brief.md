# Stage 00 — Brief

**Depends on:** nothing · **Produces:** `00-brief.md`

Fix the problem before anyone designs a solution to it. Everything downstream
inherits whatever error is in here, and this is the cheapest stage to be wrong in.

## What to do

1. **Ask, don't assume.** Ask the user directly for anything you can't establish:
   who this is for, what they do today instead, what "working" looks like, what
   the deadline and team are. Two or three real answers here beat a page of
   plausible invention.
2. Read the repo if one exists — an existing codebase constrains the plan and
   often answers the constraint questions for you.
3. Write down what success looks like in terms someone could check. "Users can
   submit and track a request without emailing anyone" is checkable; "improve
   the workflow" is not.
4. **Non-goals matter as much as goals.** The list of things this explicitly does
   not do is what stops scope creep at stage 03.
5. Recommend a track (`full` or `compact`) with a one-line reason, and ask the
   user to confirm before ending the turn.

## Artifact template

```markdown
---
phase: 00-brief
track: <full|compact>
status: draft
depends_on: []
updated: <date +%F>
---

# Brief — <project>

## Problem
<2–4 sentences. What is broken or missing today, for whom.>

## Users
| Who | What they need from this | How many |
|-----|--------------------------|----------|

## Today's workflow
<What people do now — spreadsheet, email, another tool. What specifically fails.>

## Success looks like
- <checkable outcome>

## Non-goals
- <explicitly out, with one line of why>

## Constraints
| Constraint | Detail |
|-----------|--------|
| Deadline | |
| Team | |
| Stack (fixed or open) | |
| Budget / hosting | |
| Must integrate with | |
| Compliance / regulatory | |

## Track
<full|compact> — <reason>

## Assumptions & open questions
```

## Gate

*Is this the actual problem, and is the non-goals list honest?*

Then propose stage 01 (domain model).
