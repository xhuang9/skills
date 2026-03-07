#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: delegate.sh [options] [-- prompt text]

Options:
  --model NAME
  --cwd DIR
  --output text|json|stream-json
  --system-prompt TEXT
  --append-system-prompt TEXT
  --max-budget-usd AMOUNT
  --json-schema-file PATH
  --permission-mode MODE
  --allowed-tools TOOLS
  --disallowed-tools TOOLS
  --add-dir DIR
  --prompt-file PATH
  --help

Prompt input order:
  1. --prompt-file
  2. trailing args after --
  3. stdin
EOF
}

model=""
cwd=""
output="text"
system_prompt=""
append_system_prompt=""
max_budget_usd=""
json_schema_file=""
permission_mode=""
allowed_tools=""
disallowed_tools=""
prompt_file=""
declare -a add_dirs=()
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
    --system-prompt)
      system_prompt="${2:?missing value for --system-prompt}"
      shift 2
      ;;
    --append-system-prompt)
      append_system_prompt="${2:?missing value for --append-system-prompt}"
      shift 2
      ;;
    --max-budget-usd)
      max_budget_usd="${2:?missing value for --max-budget-usd}"
      shift 2
      ;;
    --json-schema-file)
      json_schema_file="${2:?missing value for --json-schema-file}"
      shift 2
      ;;
    --permission-mode)
      permission_mode="${2:?missing value for --permission-mode}"
      shift 2
      ;;
    --allowed-tools)
      allowed_tools="${2:?missing value for --allowed-tools}"
      shift 2
      ;;
    --disallowed-tools)
      disallowed_tools="${2:?missing value for --disallowed-tools}"
      shift 2
      ;;
    --add-dir)
      add_dirs+=("${2:?missing value for --add-dir}")
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

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found in PATH" >&2
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

if [[ -n "$json_schema_file" && ! -f "$json_schema_file" ]]; then
  echo "JSON schema file not found: $json_schema_file" >&2
  exit 1
fi

if [[ -n "$cwd" ]]; then
  cd "$cwd"
fi

declare -a cmd=(
  "claude"
  "-p"
  "--no-session-persistence"
  "--output-format" "$output"
)

if [[ -n "$model" ]]; then
  cmd+=("--model" "$model")
fi

if [[ -n "$system_prompt" ]]; then
  cmd+=("--system-prompt" "$system_prompt")
fi

if [[ -n "$append_system_prompt" ]]; then
  cmd+=("--append-system-prompt" "$append_system_prompt")
fi

if [[ -n "$max_budget_usd" ]]; then
  cmd+=("--max-budget-usd" "$max_budget_usd")
fi

if [[ -n "$permission_mode" ]]; then
  cmd+=("--permission-mode" "$permission_mode")
fi

if [[ -n "$allowed_tools" ]]; then
  cmd+=("--allowed-tools" "$allowed_tools")
fi

if [[ -n "$disallowed_tools" ]]; then
  cmd+=("--disallowed-tools" "$disallowed_tools")
fi

if [[ -n "$json_schema_file" ]]; then
  cmd+=("--json-schema" "$(cat "$json_schema_file")")
fi

if [[ ${#add_dirs[@]} -gt 0 ]]; then
  for dir in "${add_dirs[@]}"; do
    cmd+=("--add-dir" "$dir")
  done
fi

cmd+=("$prompt")

exec "${cmd[@]}"
