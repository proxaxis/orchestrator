# AI Agent Isolated Development Environment

ホスト OS の環境を一切汚さずに、Devin CLI / Claude Code / Gemini CLI を自律実行モードで安全に稼働させるための隔離開発環境.

- OS: Ubuntu 26.04.1 LTS
- ネットワーク隔離: ユーザーごとの専用 Docker-in-Docker サイドカー構成 -> `network_mode: "service:dind"` で子コンテナと `localhost` を共有.
- サブネット分離: 使用ユーザごとに独立したブリッジサブネット `192.168.10.0/24` と `192.168.20.0/24` を割り当て.
- SSH ダイレクト接続: ホスト OS を経由せず、専用ポートからコンテナ内の `ubuntu` ユーザへ直接公開鍵認証でログイン可能.

## 全体構成とポート設計

| 接続先 | SSHポート | ネットワーク / サブネット | ログインユーザ |
| :--- | :--- | :--- | :--- |
| ホストOS | `49920` | ホストネットワーク | `me` / `im` |
| Container ME | `49921` | `192.168.10.0/24` (`192.168.10.10`) | `ubuntu` (`sudo` PW: `0000`) |
| Container IM | `49922` | `192.168.20.0/24` (`192.168.20.10`) | `ubuntu` (`sudo` PW: `0000`) |

## プリインストール済みの主要ツール

- AI エージェント CLI & エイリアス:
  - `devin` -> エイリアス `dvn` (`devin --permission-mode bypass`)
  - `claude` -> エイリアス `cld` (`claude --dangerously-skip-permissions`)
  - `gemini` -> エイリアス `gmn` (`gemini --yolo`)
- ランタイムとパッケージ管理:
  - Node.js `v26.13.1` / `npm`
  - Python 3 / `pip` / `venv` (`PIP_BREAK_SYSTEM_PACKAGES=1` 設定済み)
  - GitHub CLI (`gh`)
- ブラウザ自動化とメディア:
  - Playwright / Puppeteer + Chromium (日本語フォント、`xvfb`、`ffmpeg` 同梱)
- コンテナ操作:
  - `docker` / `docker compose` (`DOCKER_HOST=tcp://localhost:2375` 経由で専用 D-in-D に接続)
