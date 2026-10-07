---
name: ll-compact-clean
description: Remove ll-compact dump files that no active Claude Code session can load. Use when the user says "ll-compact clean", "clean up compact dumps", "prune the lossless dumps", "remove old context dumps", or runs /ll-compact-clean.
---

# ll-compact-clean

Dumps live under `~/.claude/skills/ll-compact/projects/`. A dump is only useful while its session can still be resumed.

## Steps

1. Dry run and show the user the table:

   ```bash
   bash ~/.claude/skills/ll-compact/scripts/clean.sh
   ```

   Columns: session, project, segment count, size, `LIVE` (a registered session with a running pid), `SRC` (the original transcript still exists in `~/.claude/projects`), age in days, action.

2. Rules the script applies:
   - Live session: keep, always.
   - Dead session and original transcript gone: delete. Claude Code has already made it unresumable.
   - Dead session and transcript present: keep, unless the user passes an age with `--days N`.

3. Delete only after the user confirms the list:

   ```bash
   bash ~/.claude/skills/ll-compact/scripts/clean.sh --yes            # rule-selected only
   bash ~/.claude/skills/ll-compact/scripts/clean.sh --days 14 --yes  # also dead sessions older than 14 days
   ```

4. Report what was deleted and what was kept. Do not delete anything the table marked `keep`.
