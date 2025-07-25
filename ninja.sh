#!/bin/bash

# セッションの存在チェック関数
check_session() {
  local session_name="$1"
  # list-sessionsの出力を確認
  if tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -q "^${session_name}$"; then
    return 0  # セッションが存在する
  else
    # has-sessionでも確認（killed状態のセッション用）
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
      return 1  # セッションが存在しない
    fi
  fi
}

# 重複セッション名の処理関数
generate_unique_session_name() {
  local base_name="$1"
  local new_name="$base_name"
  local counter=1

  # ベース名が既に存在するか確認
  if check_session "$new_name"; then
    # 連番付きの名前を試す
    while check_session "${base_name}(${counter})"; do
      ((counter++))
    done
    new_name="${base_name}(${counter})"
  fi

  echo "$new_name"
}

ninja() {
  # ヘルプオプションの早期チェック
  if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: ninja [-n <session_name>] [-l <log_file>] <command> ..."
    echo ""
    echo "Options:"
    echo "  -n <session_name>   Specify the tmux session name."
    echo "  --session_name <session_name> Specify the tmux session name."
    echo "  --name <session_name>        Specify the tmux session name."
    echo "  -l <log_file>       Specify the log file path."
    echo "  --log <log_file>    Specify the log file path."
    echo "  -h, --help            Show this help message and exit."
    echo ""
    echo "Note: If the specified session name already exists, (n) will be appended"
    echo "      where n is the next available number."
    echo "Default session name format: YYYYMMDD_HHMMSS"
    return 0
  fi

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local default_session_name="$timestamp"
  local session_name="$default_session_name"
  local log_file=""
  local command=""

  # オプションの解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--session_name|--name)
        if [[ -n "$2" ]]; then
          session_name="$2"
          shift 2
        else
          echo "Error: $1 requires an argument." >&2
          return 1
        fi
        ;;
      -l|--log)
        if [[ -n "$2" ]]; then
          log_file="$2"
          shift 2
        else
          echo "Error: $1 requires an argument." >&2
          return 1
        fi
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        # オプションでない引数（コマンド）に到達
        command="$@"
        break
        ;;
    esac
  done

  # ログファイルのディレクトリを作成
  if [[ -n "$log_file" ]]; then
    mkdir -p "$(dirname "$log_file")"
  fi

  if [[ -n "$command" ]]; then
    local original_name="$session_name"
    # セッション名の重複をチェックし、必要に応じて新しい名前を生成
    if [[ "$session_name" != "$default_session_name" ]]; then
      session_name=$(generate_unique_session_name "$session_name")
      if [[ "$session_name" != "$original_name" ]]; then
        echo "Session \"$original_name\" already exists, using \"$session_name\" instead."
      fi
    fi

    # セッション情報の表示
    echo -e "session-name : $session_name"
    echo -e "command\t: $command"
    if [[ -n "$log_file" ]]; then
      echo -e "logfile\t: $log_file"
      # ログ出力ありの場合は、シェル経由で実行してリダイレクト
      tmux new-session -d -s "$session_name" bash -c \
      "echo \"$command > $log_file 2>&1\"; $command > \"$log_file\" 2>&1"
    else
      # コマンドを直接実行
      tmux new-session -d -s "$session_name" bash -c "echo \"$command\"; $command"
    fi
  else
    echo "Error: No command specified." >&2
    return 1
  fi
}
