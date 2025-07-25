#!/bin/bash

# テストが失敗した場合に即座に終了
set -e

# 必要な関数をsourceする
source ./ninja.sh

# テストケースの実行結果を保存する配列
declare -a failed_tests=()

# テスト用の一時ディレクトリ
TEST_DIR="/tmp/ninja_test"

# テスト開始前の準備
setup() {
  echo "Setting up test environment..."
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  # 既存のtmuxセッションをクリーンアップ
  tmux kill-server 2>/dev/null || true
}

# テスト終了後のクリーンアップ
cleanup() {
  echo "Cleaning up test environment..."
  cd ..
  rm -rf "$TEST_DIR"
  tmux kill-server 2>/dev/null || true
}

# テスト実行用関数
run_test() {
  local test_name="$1"
  local test_function="$2"
  echo "Running test: $test_name"
  if $test_function; then
    echo "✓ Test passed: $test_name"
    return 0
  else
    echo "❌ Test failed: $test_name"
    failed_tests+=("$test_name")
    return 1
  fi
}

# デフォルトセッション名のテスト
test_default_session_name() {
  local output
  output=$(ninja echo "test" 2>&1)
  # タイムスタンプ形式のセッション名が含まれているか確認
  if echo "$output" | grep -q "session-name : [0-9]\{8\}_[0-9]\{6\}"; then
    return 0
  else
    return 1
  fi
}

# カスタムセッション名のテスト
test_custom_session_name() {
  local session_name="test_session"
  local output
  output=$(ninja -n "$session_name" echo "test" 2>&1)
  if echo "$output" | grep -q "session-name : $session_name"; then
    return 0
  else
    return 1
  fi
}

# セッション名重複時の連番付与テスト
test_duplicate_session_name() {
  local session_name="duplicate_test"
  # 1回目の実行
  ninja -n "$session_name" -l $TEST_DIR/.log1 yes > /dev/null
  # 2回目の実行（重複）
  local output
  output=$(ninja -n "$session_name" yes 2>&1)
  if echo "$output" | grep -q "session-name : ${session_name}(1)"; then
    return 0
  else
    return 1
  fi
}

# ログファイル出力のテスト
test_log_file() {
  local log_file="$TEST_DIR/test.log"
  local test_message="test_log_message"
  ninja -l "$log_file" echo "$test_message" > /dev/null
  # ログファイルが作成されるまで少し待つ
  sleep 1
  if [[ -f "$log_file" ]] && grep -q "$test_message" "$log_file"; then
    return 0
  else
    return 1
  fi
}

# メイン処理
main() {
  setup

  # テストケースの実行
  run_test "Default session name" test_default_session_name
  run_test "Custom session name" test_custom_session_name
  run_test "Duplicate session name" test_duplicate_session_name
  run_test "Log file output" test_log_file

  cleanup

  # テスト結果の表示
echo -e "\nTest Results:"
  if [[ ${#failed_tests[@]} -eq 0 ]]; then
    echo "All tests passed! 🎉"
    exit 0
  else
    echo "Failed tests:"
    for test in "${failed_tests[@]}"; do
      echo " - $test"
    done
    exit 1
  fi
}

# テストの実行
main
