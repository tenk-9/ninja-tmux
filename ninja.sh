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
    echo "Default session name format:<ctrl3348>MMDD_HHMMSS"
    return 0
  fi

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local default_session_name="$timestamp"
  local session_name="$default_session_name"
  local log_file=""
  local command="$@"

  while getopts "n:l:" opt; do
    case "$opt" in
      n)
        session_name="$OPTARG"
        shift # OPTIND を進める
        shift # -n と引数をスキップ
        command="$@"
        break # オプション処理を終了
        ;;
      l)
        log_file="$OPTARG"
        shift # OPTIND を進める
        shift # -l と引数をスキップ
        command="$@"
        break # オプション処理を終了
        ;;
      \?)
        echo "Usage: ninja [-n <session_name>] <command> ..." >&2
        return 1
        ;;
    esac
  done

  # ログファイルのディレクトリを作成
  if [[ -n "$log_file" ]]; then
    mkdir -p "$(dirname "$log_file")"
  fi

  while [[ $# -gt 0 && "${1:0:1}" == "-" ]]; do
    case "$1" in
      --session_name)
        if [[ -n "$2" ]]; then
          session_name="$2"
          shift
          shift
        else
          echo "Error: --session_name requires an argument." >&2
          return 1
        fi
        ;;
      --name)
        if [[ -n "$2" ]]; then
          session_name="$2"
          shift
          shift
        else
          echo "Error: --name requires an argument." >&2
          return 1
        fi
        ;;
      --log)
        if [[ -n "$2" ]]; then
          log_file="$2"
          shift
          shift
        else
          echo "Error: --log requires an argument." >&2
          return 1
        fi
        ;;
      *)
        break # オプションでない引数に到達
        ;;
    esac
  done
  shift $((OPTIND - 1)) # getopts で処理したオプション以外の引数を削除

  command="$@"

  if [[ -n "$command" ]]; then
    # セッション名の重複チェック
    if check_session "$session_name"; then
      # アクティブなセッションが存在する場合、デフォルト名を使用
      echo "Session \"$session_name\" already exists, using default session name instead."
      session_name="$default_session_name"
    fi

    # セッション情報の表示
    echo -e "session-name : $session_name"
    echo -e "command\t: $command"
    if [[ -n "$log_file" ]]; then
      echo -e "logfile\t: $log_file"
      # ログ出力ありの場合は、シェル経由で実行してリダイレクト
      tmux new-session -d -s "$session_name" "exec $command > '$log_file' 2>&1" \; detach
    else
      # コマンドを直接実行
      tmux new-session -d -s "$session_name" "exec $command" \; detach
    fi
  else
    echo "Error: No command specified." >&2
    return 1
  fi
}
