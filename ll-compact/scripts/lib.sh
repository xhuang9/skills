# Shared by the ll-compact scripts. Source, do not execute.
set -u
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DATA_ROOT="$PLUGIN_ROOT/projects"
JQ="$(command -v jq 2>/dev/null || echo /opt/homebrew/bin/jq)"

# data_path <transcript_path> <session_id>
# Mirrors Claude Code's own layout: projects/<encoded-cwd>/<session-id>.jsonl
data_path() {
  printf '%s/%s/%s.jsonl' "$DATA_ROOT" "$(basename "$(dirname "$1")")" "$2"
}
