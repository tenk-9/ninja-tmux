#!/bin/bash

# Bash 4.3以上が必要（nameref機能を使用するため）
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
  echo "Error: This script requires Bash 4.3 or later (current: $BASH_VERSION)" >&2
  exit 1
fi

# セッション管理モジュール
check_session() {
  local session_name="$1"
  [[ -z "$session_name" ]] && return 1
  
  tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -q "^${session_name}$" ||
  tmux has-session -t "$session_name" 2>/dev/null
}

generate_unique_session_name() {
  local base_name="$1"
  [[ -z "$base_name" ]] && { echo "Error: empty session name" >&2; return 1; }
  
  local new_name="$base_name"
  local counter=1

  if check_session "$new_name"; then
    while check_session "${base_name}(${counter})"; do
      ((counter++))
    done
    new_name="${base_name}(${counter})"
  fi

  echo "$new_name"
}

# ヘルプ表示モジュール
show_help() {
  cat << 'EOF'
Usage: ninja [-n <session_name>] [-l <log_file>] <command> ...

Options:
  -n <session_name>         Specify the tmux session name.
  --session_name <session_name> Specify the tmux session name.
  --name <session_name>     Specify the tmux session name.
  -l <log_file>             Specify the log file path.
  --log <log_file>          Specify the log file path.
  -h, --help                Show this help message and exit.

Note: If the specified session name already exists, (n) will be appended
      where n is the next available number.
Default session name format: YYYYMMDD_HHMMSS
EOF
}

# オプション解析モジュール
parse_options() {
  local -n opts="$1"
  shift
  
  local default_session_name="$(date +%Y%m%d_%H%M%S)"
  opts[session_name]="$default_session_name"
  opts[default_session_name]="$default_session_name"
  opts[log_file]=""
  opts[command]=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--session_name|--name)
        [[ -z "$2" ]] && { echo "Error: $1 requires an argument." >&2; return 1; }
        opts[session_name]="$2"
        shift 2
        ;;
      -l|--log)
        [[ -z "$2" ]] && { echo "Error: $1 requires an argument." >&2; return 1; }
        opts[log_file]="$2"
        shift 2
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        opts[command]="$*"
        return 0
        ;;
    esac
  done
  
  [[ -z "${opts[command]}" ]] && { echo "Error: No command specified." >&2; return 1; }
}

# ログファイル準備モジュール
prepare_log_file() {
  local log_file="$1"
  [[ -n "$log_file" ]] && mkdir -p "$(dirname "$log_file")"
}

# tmuxセッション作成モジュール
create_tmux_session() {
  local session_name="$1"
  local command="$2"
  local log_file="$3"
  
  # セッション名の安全性を検証
  if [[ ! "$session_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid session name \"$session_name\". Only alphanumeric characters, underscores, and hyphens are allowed." >&2
    return 1
  fi
  
  # シェルインジェクション対策のためのエスケープ
  local escaped_session_name=$(printf %q "$session_name")
  local escaped_command=$(printf %q "$command")
  
  if [[ -n "$log_file" ]]; then
    local escaped_log_file=$(printf %q "$log_file")
    tmux new-session -d -s "$escaped_session_name" "exec echo $escaped_command' > '$escaped_log_file' 2>&1' & $command > '$escaped_log_file' 2>&1" \; detach
  else
    tmux new-session -d -s "$escaped_session_name" "exec echo $escaped_command & $command" \; detach
  fi
}

# セッション情報表示モジュール
show_session_info() {
  local session_name="$1"
  local command="$2"
  local log_file="$3"
  
  echo "session-name : $session_name"
  echo -e "command\t: $command"
  [[ -n "$log_file" ]] && echo -e "logfile\t: $log_file"
}

ninja() {
  [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] && { show_help; return 0; }
  
  local -A options
  parse_options options "$@" || return 1
  
  local session_name="${options[session_name]}"
  local original_name="$session_name"
  
  # セッション名の重複チェック（デフォルト名以外の場合のみ）
  if [[ "$session_name" != "${options[default_session_name]}" ]]; then
    session_name=$(generate_unique_session_name "$session_name") || return 1
    if [[ "$session_name" != "$original_name" ]]; then
      echo "Session \"$original_name\" already exists, using \"$session_name\" instead."
    fi
  fi
  
  prepare_log_file "${options[log_file]}"
  show_session_info "$session_name" "${options[command]}" "${options[log_file]}"
  create_tmux_session "$session_name" "${options[command]}" "${options[log_file]}"
}
