# ninja-tmux

コマンドをバックグラウンドで実行するための、より柔軟なtmuxベースのツール

## 概要

`ninja`は、`nohup command &`の代替として使える便利なBash関数です。従来の`nohup`コマンドと同様にバックグラウンド実行が可能で、さらに以下の利点があります：

- tmuxセッションを利用することで、後からコマンドの実行状態を確認可能
- セッション名を指定して管理が容易
- ログアウトしても実行が継続
- 出力をtmuxセッション内で確認可能、またはログファイルに出力可能

## インストール方法

1. スクリプトをダウンロードします：
```bash
git clone https://github.com/YourUsername/ninja-tmux.git
```

2. `~/.bashrc`に以下の行を追加して関数を読み込みます：
```bash
source ~/path/to/ninja.sh
```

3. 変更を反映させます：
```bash
source ~/.bashrc
```

## 使用方法

### 基本的な使い方（出力はtmuxセッションに表示）
```bash
# 従来の方法
nohup long_running_command &

# ninjaを使用
ninja "long_running_command"
```

### ログファイルを指定して実行（標準出力とエラー出力をログファイルに保存）
```bash
ninja -l /path/to/output.log "long_running_command"
# または
ninja --log /path/to/output.log "long_running_command"
```

### セッション名とログファイルを指定して実行
```bash
ninja -n session_name -l /path/to/output.log "long_running_command"
```

### ヘルプを表示
```bash
ninja -h
# または
ninja --help
```

## nohupとの比較

### ninja の利点
1. **セッション管理**
   - セッション名を指定して実行状態を管理可能
   - `tmux attach -t session_name`で実行中のコマンドの状態を確認可能

2. **柔軟な出力制御**
   - デフォルトではtmuxセッション内で出力を表示
   - `-l`オプションで指定したログファイルに標準出力とエラー出力を保存可能
   - nohup.outのような固定ファイル名に制限されない
   - 複数のコマンドの出力を個別のログファイルで管理可能

3. **柔軟な操作**
   - 実行中のセッションに後からアタッチして状態確認や操作が可能
   - セッション名による管理で複数のバックグラウンドタスクを整理可能

## オプション

- `-n <session_name>`: tmuxセッション名を指定
- `--session_name <session_name>`: tmuxセッション名を指定（ロング形式）
- `--name <session_name>`: tmuxセッション名を指定（ロング形式）
- `-l <log_file>`: ログファイルのパスを指定（標準出力とエラー出力を保存）
- `--log <log_file>`: ログファイルのパスを指定（ロング形式）
- `-h, --help`: ヘルプメッセージを表示

## tmuxの基本操作

tmuxは端末多重化ソフトウェアで、複数の仮想端末（セッション）を管理できます。
ninjaで作成したセッションの基本的な操作方法は以下の通りです：

- セッション一覧の表示: `tmux ls`
- セッションへの接続: `tmux attach -t セッション名`
- セッションから抜ける: `Ctrl + b, d`
- セッションの終了: `tmux kill-session -t セッション名`

tmuxの詳しい使い方については、[tmuxの基本操作ガイド](docs/tmux_guide.md)を参照してください。

## 要件

- tmux
- Bash 4.3以上（namerefs機能を使用するため）

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照してください。
