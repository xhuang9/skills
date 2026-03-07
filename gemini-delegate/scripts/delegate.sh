#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: delegate.sh [options] [-- prompt text]

Options:
  --model NAME
  --cwd DIR
  --output text|json|stream-json
  --approval-mode MODE
  --allowed-mcp-server NAME
  --include-directory DIR
  --extension NAME
  --prompt-file PATH
  --help

Prompt input order:
  1. --prompt-file
  2. trailing args after --
  3. stdin
EOF
}

sanitize_output() {
  awk '
    /^Loaded cached credentials\.$/ { next }
    /^Skill ".*" from ".*" is overriding the built-in skill\.$/ { next }
    /^Ignore file not found: .*\.geminiignore, continue without it\.$/ { next }
    /^Hook registry initialized with [0-9]+ hook entries$/ { next }
    /^Hook system initialized successfully$/ { next }
    /^Experiments loaded/ { next }
    /^Approval mode "plan" is only available when experimental\.plan is enabled\. Falling back to "default"\.$/ { next }
    { print }
  '
}

model=""
cwd=""
output="text"
approval_mode=""
prompt_file=""
declare -a allowed_mcp_servers=()
declare -a include_directories=()
declare -a extensions=()
declare -a prompt_parts=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      model="${2:?missing value for --model}"
      shift 2
      ;;
    --cwd)
      cwd="${2:?missing value for --cwd}"
      shift 2
      ;;
    --output)
      output="${2:?missing value for --output}"
      shift 2
      ;;
    --approval-mode)
      approval_mode="${2:?missing value for --approval-mode}"
      shift 2
      ;;
    --allowed-mcp-server)
      allowed_mcp_servers+=("${2:?missing value for --allowed-mcp-server}")
      shift 2
      ;;
    --include-directory)
      include_directories+=("${2:?missing value for --include-directory}")
      shift 2
      ;;
    --extension)
      extensions+=("${2:?missing value for --extension}")
      shift 2
      ;;
    --prompt-file)
      prompt_file="${2:?missing value for --prompt-file}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      prompt_parts=("$@")
      break
      ;;
    *)
      prompt_parts+=("$1")
      shift
      ;;
  esac
done

if ! command -v gemini >/dev/null 2>&1; then
  echo "gemini CLI not found in PATH" >&2
  exit 127
fi

if [[ "$output" != "text" && "$output" != "json" && "$output" != "stream-json" ]]; then
  echo "Invalid --output value: $output" >&2
  exit 1
fi

prompt=""
if [[ -n "$prompt_file" ]]; then
  if [[ ! -f "$prompt_file" ]]; then
    echo "Prompt file not found: $prompt_file" >&2
    exit 1
  fi
  prompt="$(cat "$prompt_file")"
elif [[ ${#prompt_parts[@]} -gt 0 ]]; then
  printf -v prompt '%s ' "${prompt_parts[@]}"
  prompt="${prompt% }"
elif [[ ! -t 0 ]]; then
  prompt="$(cat)"
fi

trimmed_prompt="${prompt//[$'\t\r\n ']}"
if [[ -z "$trimmed_prompt" ]]; then
  echo "No prompt provided" >&2
  usage >&2
  exit 1
fi

if [[ -n "$cwd" ]]; then
  cd "$cwd"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -a cmd=(
  "gemini"
  "-p" "$prompt"
  "--output-format" "$output"
)

if [[ -n "$model" ]]; then
  cmd+=("--model" "$model")
fi

if [[ -n "$approval_mode" ]]; then
  cmd+=("--approval-mode" "$approval_mode")
fi

if [[ ${#allowed_mcp_servers[@]} -gt 0 ]]; then
  for server in "${allowed_mcp_servers[@]}"; do
    cmd+=("--allowed-mcp-server-names" "$server")
  done
fi

if [[ ${#include_directories[@]} -gt 0 ]]; then
  for dir in "${include_directories[@]}"; do
    cmd+=("--include-directories" "$dir")
  done
fi

if [[ ${#extensions[@]} -gt 0 ]]; then
  for extension in "${extensions[@]}"; do
    cmd+=("--extensions" "$extension")
  done
fi

if [[ -n "${NODE_OPTIONS:-}" ]]; then
  export NODE_OPTIONS="--require ${script_dir}/suppress_console.cjs ${NODE_OPTIONS}"
else
  export NODE_OPTIONS="--require ${script_dir}/suppress_console.cjs"
fi

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
cleanup() {
  rm -f "$stdout_file" "$stderr_file"
}
trap cleanup EXIT

set +e
("${cmd[@]}") >"$stdout_file" 2>"$stderr_file"
status=$?
set -e

stdout_content="$(cat "$stdout_file")"
stderr_content="$(sanitize_output < "$stderr_file")"

if [[ "$output" == "json" || "$output" == "stream-json" ]]; then
  if [[ -n "$stdout_content" ]]; then
    printf '%s\n' "$stdout_content"
  elif [[ -n "$stderr_content" ]]; then
    printf '%s\n' "$stderr_content" >&2
  fi
else
  if [[ -n "$stderr_content" ]]; then
    printf '%s\n' "$stderr_content" >&2
  fi
  if [[ -n "$stdout_content" ]]; then
    printf '%s\n' "$stdout_content"
  fi
fi

exit "$status"
