# AI Agent Isolated Development Environment

ホスト OS の環境を一切汚さずに、Devin CLI / Claude Code / Gemini CLI を自律実行モードで安全に稼働させるための隔離開発環境.

- OS: Ubuntu 26.04.1 LTS
- ネットワーク隔離: ユーザーごとの専用 Docker-in-Docker サイドカー構成 -> `network_mode: "service:dind"` で子コンテナと `localhost` を共有.
- サブネット分離: ユーザーごとに独立したブリッジサブネット `192.168.10.0/24` と `192.168.20.0/24` を割り当て.
- SSH ダイレクト接続: ホスト OS を経由せず、専用ポートからコンテナ内の `ubuntu` ユーザへ直接公開鍵認証でログイン可能.

## 全体構成・ポート設計

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
  - `docker` / `docker compose`（`DOCKER_HOST=tcp://localhost:2375` 経由で専用 DinD に接続）

## ディレクトリ構成

共通イメージ `orchestrator:latest` で1度だけビルドし、各ユーザは自分のホームディレクトリ内の `docker-compose.yml` と `.env` を使って独立したコンテナを起動.

```text
/home/me/orchestrator/              # このリポジトリの配置場所
├── Dockerfile
└── README.me

/home/me/orchestrator/           # ユーザ me 専用の実行ディレクトリ
├── docker-compose.yml
└── .env

/home/im/orchestrator/           # ユーザ im 専用の実行ディレクトリ
├── docker-compose.yml
└── .env
```
