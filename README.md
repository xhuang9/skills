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
| `claude-delegate` | Lets Codex hand a narrowly scoped task to Claude CLI, including usage estimation, a lightweight usage gate, and a non-interactive delegation wrapper. | I have multiple AI subscriptions in the roughly $20/month range, and I want to make full use of all available quota. I also strongly prefer the Codex UI, so I wanted Codex to be able to call Claude Code directly without making me manually decide every time which task should go to Claude. Codex is especially good at reading docs and finding the right context, while Claude Code is very strong at execution and coding. In practice, Codex planning plus Claude execution is a very effective combination. |

## Notes

- This repository is intended to grow over time as more day-to-day workflows become reusable skills.
- Each skill should stay grounded in a concrete problem it was built to solve.
