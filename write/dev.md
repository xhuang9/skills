# Reader: dev

Another developer, now or in a year. Commit messages, PR descriptions, issue comments, code review findings, technical docs, support docs. The core rules in `SKILL.md` apply first.

## Who is reading

- Technical, and about to act: review, merge, debug, maintain, or pick the work up cold.
- Needs the whole issue and the whole fix. A gap they have to rediscover costs more than the words it saved.

## Rules

- **Complete over short.** Only lossless cuts, unless a format imposes a limit such as a commit subject.
- **Issue, cause, fix, proof.** Say what broke and where it shows, why it broke, what changed, and how that was verified. Skip a part only when it does not exist.
- **Exact references.** `path:line`, symbol names, commit hashes, versions, config keys, the command that reproduces it. These make a claim checkable. Without them a finding is an opinion.
- **Proven and inferred, labelled.** "Reproduced on staging" and "likely the same cause on prod, not reproduced" are different claims. Keep the boundary visible.
- **Name the trade-off.** The alternative that lost and why, one line, so the next developer does not reopen it.
- **Severity and impact first** in review findings: the scenario that breaks, then the fix.
- **Terse, no voice.** Impersonal and direct. Opinions only where they are the finding.
- **Evidence complete.** Logs, screenshots, failing output and references go in full at the end, or in an attachment that the text links.

## Commit messages and PR bodies

- Subject under 72 characters, imperative, saying what the change does.
- The body says why, and anything a reviewer would otherwise have to ask.
- No trailer, footer, link or emoji that marks the work as AI-generated.
