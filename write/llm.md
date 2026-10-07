# Reader: llm

Another agent, or a later session of this one. `.readme/` chunks and section indexes, CLAUDE.md and AGENTS.md, skill files, sub-agent and Codex prompts, handoffs, memory files, task context folders. The core rules in `SKILL.md` apply first.

## Who is reading

- It reads every word, literally, with no shared memory of this conversation. Anything not on the page does not exist for it.
- It pays for every token, and every token competes with the task for attention.
- It follows instructions it can check and ignores ones it cannot.

## Rules

- **Lossless first.** Apply every lossless cut from `SKILL.md`. Never apply a lossy one unless a limit is stated. A dropped caveat in an agent doc becomes a wrong action later.
- **No voice.** Terse and impersonal. No opinions, no first person, no rhythm for its own sake. Voice belongs to `me.md`.
- **Self-contained.** No "as discussed", "see above", "the earlier fix". Name the file, the commit, the decision. Use absolute paths when the reader may start in another directory.
- **Exact identifiers.** The real file, symbol, flag, command and version. Never a description of one.
- **Every rule checkable, with its why.** "Keep components under 200 lines, because the lint gate fails above that" beats "keep components small". A rule with no reason gets bent; a rule nobody can check gets ignored.
- **One meaning, one home.** State a rule once and point to it from elsewhere. Two copies drift into two rules.
- **Steps before reference.** When the doc tells the reader to do something, the procedure comes first and the background after.
- **Do not restate the environment.** Leave out what the reader can see in the code, the git history or the tool schema. Write the non-obvious part.
- **Structure over prose.** Tables for facts with shared dimensions, numbered lists for procedures, short declarative sentences for single facts.
- **Write what is true now.** When revising, delete removed content outright. No "previously", no "no longer", no note saying what was cut.
- **Separate proven from inferred.** Mark anything unverified as unverified, so the reader does not act on a guess.

## Sub-agent and Codex prompts

The receiving agent inherits no skills and no conversation.

- State the goal, the done condition, and the output format the result must come back in.
- Inline every guardrail it must follow, as full text. Naming a skill is not enough.
- Include the paths, identifiers and constraints it needs. Leave out the history of how you got here.
- Ask for a result that is complete and uncapped. Concentration happens later, when the result reaches me.
