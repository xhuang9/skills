# skills

This repository is a small collection of shareable skills that help with my day-to-day work.

Most of these skills were created after solving recurring real-world problems in my own workflow and then turning the solution into something reusable.

If anything here looks similar to another tool, workflow, or prompt pattern, that is coincidental.

## Purpose

- Share practical skills that came out of actual daily work
- Preserve useful workflows as reusable building blocks
- Make it easier to reuse and adapt those workflows in other environments

## Skills

| Name | Function | Background / Reason to build |
| --- | --- | --- |
| `write` | Wording rules for every piece of English an agent writes, routed by who reads it: the developer in chat (`me.md`), another agent (`llm.md`), a non-technical PM (`pm.md`), another developer (`dev.md`) or the public (`public.md`). Shared rules cover Australian spelling, sentence shape, AI-tell patterns and compression that never drops a fact. | I had several output skills (de-AI-ing prose, Australian spelling, reply length, action-first replies, Australian copywriting) that repeated and sometimes contradicted each other. One skill with a reader router gives each rule a single home, and format skills only decide sections and order. It replaces `au-copywriter`, which now lives on as `public.md`. |
| `plan-software` | A staged planning ladder for building software: brief, domain model, use cases, scope, screen map, data model, contracts, design, architecture, acceptance and build plan, one stage per turn, each with a reviewable artifact. | Jumping straight into code on a new app skipped the decisions that caused rework later. One stage per turn makes every decision visible and reviewable before anything is built. |
| `local-skills` | Captures a durable project rule as a project-local "guardrail skill", so future sessions honour it. | Rules buried in `CLAUDE.md` or a docs chunk were missed. A skill's description is always loaded and fires the moment its keywords match, which makes it the more reliable place for a "never do this again" rule. |
| `artifact-rules` | Readability floor for HTML pages and artifacts: no text under 18px, and WCAG 2.2 AAA contrast (7:1) in both light and dark themes. Includes `contrast.py`, which checks colour pairs. | Generated pages kept defaulting to 13 to 15px labels and mid-grey secondary text that was tiring to read. |
| `ll-compact` | Lossless compact for Claude Code: `/compact ll` saves the full transcript plus a retrieval guide before compaction and puts the guide back into the fresh context. Includes `ll-compact-clean` to prune old dumps. | Built-in compaction is lossy. Decisions get paraphrased and exact commands disappear, and the original transcript is deleted later. This keeps the earlier turns recoverable. |

## Notes

- This repository is intended to grow over time as more day-to-day workflows become reusable skills.
- Each skill should stay grounded in a concrete problem it was built to solve.
