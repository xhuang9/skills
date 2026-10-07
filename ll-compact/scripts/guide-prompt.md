You write a retrieval guide for a dump of a Claude Code session that is about to be compacted. The dump survives on disk. A future agent reads your guide, then pulls single turns or short ranges by number. Your job is to make that lookup exact: every entry names the turn that holds the fact, so the agent reads one turn instead of a range.

Input: numbered turns in the form "[n] role: text". Tool calls appear as "> Name path=... input" lines under the assistant turn that made them; their results are the following "tool" turn. Text is truncated.

Output exactly one JSON object and nothing else. No code fences, no prose.

{"summary": "<=60 words: what the session is about and where it stands at the last turn",
 "toc": [{"topic": "<=8 words", "turns": "a-b", "key": [n, n], "when": "<=15 words: the question that should send an agent here"}],
 "decisions": [{"t": n, "by": "user" | "assistant", "what": "<=20 words"}],
 "corrections": [{"t": n, "what": "<=20 words: wrong belief -> corrected fact"}],
 "artifacts": [{"t": n, "path": "file path, ticket id, URL or commit", "what": "<=12 words"}],
 "state": [{"t": n, "what": "<=15 words: status of a ticket, branch, deploy or service as last seen"}],
 "open": [{"t": n, "what": "<=15 words"}]}

Rules:
- "t" and "key" are turn numbers from the input. Never invent one. Point at the turn that holds the payload: the user's own words for a decision, the tool turn or the "> Write/Edit/Bash" line for file contents, the tool turn for command output, the assistant turn only when it is the sole source.
- toc: 4 to 12 entries in timeline order, contiguous ranges, 1 to 3 key turns each.
- decisions: what the user chose or constrained, kept in the user's meaning. Up to 12.
- corrections: places where an earlier belief in the session was found wrong and fixed. Up to 8. Omit the field if none.
- artifacts: files created or changed, tickets, commits, docs. Up to 12. Prefer the turn holding the final version.
- state: snapshots that can move after the dump (ticket status, branch dirtiness, deploy, external approvals). Up to 8. Omit the field if none.
- open: unfinished items at the last turn. Up to 8.
- No filler. Whole output under 700 words.
