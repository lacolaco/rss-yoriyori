# CLAUDE.md

## Principles

### t_wada style TDD

**このプロジェクトでは機能追加・変更時にt_wadaスタイルのTDDを必ず適用する。例外なし。**

参考: [テスト駆動開発の定義 - t-wadaのブログ](https://t-wada.hatenablog.jp/entry/canon-tdd-by-kent-beck)

#### TDDの5ステップ（Kent Beck定義）

1. **テストリスト作成**: テストしたいシナリオのリストを書く
2. **1つ選んでテスト**: リストから1つだけ選び、失敗するテストを書く
3. **テストを通す**: 最小限の実装でテストを成功させる
4. **リファクタリング**: 設計を改善する（毎サイクル必須）
5. **繰り返し**: リストが空になるまで2に戻る

#### 計画の記録

**PLAN.local.md を常に参照・更新する。** テストリスト、サブタスク進捗、設計メモなど動的な計画はすべてここに記録。

#### 計画テンプレート（PLAN.local.mdに書く）

```markdown
## タスク: [タスク名]

### テストリスト
- [ ] 1. [振る舞いシナリオ1]
- [ ] 2. [振る舞いシナリオ2]
- [ ] 3. [振る舞いシナリオ3]

**ステータス: 承認待ち**

### 実行ログ

#### テスト1: [シナリオ名]
- RED: [失敗内容]
- GREEN: [実装内容]
- REFACTOR:
  - 命名: [確認結果・改善内容]
  - 重複: [確認結果・改善内容]
  - 責務: [確認結果・改善内容]
  - 抽出: [関数/変数の抽出有無]
```

#### 厳守事項

- **テストリストを先に作る**: コードを書く前にシナリオを洗い出す
- **承認を得てから実行**: テストリスト作成後、ユーザー承認なしに実行フェーズに進まない
- **1つずつ**: 複数のテストを一度に書かない
- **失敗を確認**: REDで `make test` 実行、失敗を見届けてからGREEN
- **毎回リファクタ**: 以下4項目を必ず確認し、結果を記録する
  - 命名: 変数名・関数名は意図を表しているか
  - 重複: 同じロジックが複数箇所にないか
  - 責務: 1つの関数が複数のことをしていないか
  - 抽出: ヘルパー関数や変数への抽出が必要か

#### TDDでないもの（t_wada指摘）

- テストを先にたくさん書いてしまう
- リファクタリングが行われていない
- テストを書く過程で設計が変わらない

ユーザーが実装する場合:
- Claudeはスキャフォールディング（ファイル特定、TODO(human)配置）のみ
- テスト・実装コードはユーザーが書く
- RED/GREEN/REFACTORの各フェーズはユーザーの報告を待つ

### 作業前確認

作業前に「何をどうするか」を宣言し、ユーザーの確認を得てから実行する。

### 確認不要事項

- TDDの適用（確認せず適用する）

### コミット前チェック（必須）

**コミット前に以下を必ず実行し、両方パスすることを確認する。省略禁止。**

```sh
make format-check  # フォーマット確認
make test          # テスト実行
```

CIは `make format-check` と `make test` の両方を実行する。ローカルで片方しか確認しないと、CIで失敗する。

## プロジェクト概要

rss_yoriyoriはGleamで書かれたRSSフィードアグリゲーター。GleamはErlangとJavaScriptにコンパイルされる型安全な関数型言語。

## ビルドコマンド

```sh
make build      # コンパイル
make up        # 実行
make test        # テスト実行（必須：Docker Compose経由）
gleam docs build # ドキュメント生成
```

## テスト

**重要: テストは必ず `make test` で実行すること。`gleam test` は使わない。**

理由：
- storage_testはMinIOが必要
- Docker Compose経由で実行することで、MinIOが自動起動する
- `gleam test` では環境変数がなく、storage_testが失敗する

テストは`test/`ディレクトリに配置。gleeunitフレームワークを使用。テスト関数は`_test`サフィックスが必須。

## プロジェクト構成

```
├── src/                  # ソースコード
│   ├── rss_yoriyori.gleam  # エントリーポイント
│   ├── router.gleam        # HTTPルーティング
│   ├── config.gleam        # 設定読み込み
│   ├── feed/               # フィード処理
│   │   ├── parser.gleam    # RSS/Atomパーサー
│   │   ├── aggregator.gleam # フィード集約
│   │   ├── generator.gleam # RSS生成
│   │   └── types.gleam     # 型定義
│   └── storage/
│       └── s3.gleam        # S3互換ストレージ
├── test/                 # テストコード
├── terraform/            # GCPインフラ定義
├── docs/                 # ドキュメント
├── gleam.toml            # プロジェクト設定
├── feeds.json            # フィード設定（Git管理）
├── compose.yaml          # ローカル開発用
└── Dockerfile            # 本番ビルド
```

## Gleam言語

詳細は [docs/gleam-tour.md](docs/gleam-tour.md) を参照。

## Docker設定

- mist HTTPサーバーはデフォルトで`127.0.0.1`にバインド
- Docker対応には`mist.bind("0.0.0.0")`が必要
- ビルダーとランタイムのErlangバージョンを一致させること

## 開発ワークフロー

### ローカル開発

```sh
make up    # ビルド＆起動（Docker Compose）
make down  # 停止
make logs  # ログ表示
```

### 本番デプロイ

mainブランチへのPR作成時にデプロイワークフローが起動。production環境の承認後に実行される。

```sh
make plan    # Terraform plan確認（ローカル）
```

### IaC構成

- `compose.yaml` - ローカル開発
- `docker-bake.hcl` - 本番ビルド定義
- `Makefile` - コマンド統一
- `.github/workflows/test.yml` - CI（テスト、lint、terraform plan）
- `.github/workflows/deploy.yml` - CD（承認後デプロイ）
- `terraform/` - GCPインフラ定義

### CI/CDフロー

1. PRを作成 → test.yml（テスト、lint、terraform plan）
2. CIパス → deploy.yml起動（production環境の承認待ち）
3. 承認 → Docker build & push → terraform apply
4. デプロイ完了 → PRマージ可能

### アーキテクチャ制約

- devcontainer: ARM (aarch64)
- Cloud Run: AMD64 (x86_64)
- ErlangはQEMUエミュレーション非対応 → ローカルからamd64ビルド不可
- 本番デプロイはGitHub Actions（amd64ネイティブ）で実行

## ストレージ連携

S3互換APIを使用してMinIO（ローカル）とGCS（本番）の両方に対応：

```gleam
import storage/s3

// 環境変数から設定を読み込み
let assert Ok(config) = s3.config_from_env()

// ファイルアップロード
s3.put_object(config, "path/to/file.xml", content, "application/xml")

// ファイル取得
case s3.get_object(config, "path/to/file.xml") {
  Ok(content) -> // ...
  Error(s3.NotFoundError) -> // 404
  Error(_) -> // その他エラー
}
```

### 環境変数

- `S3_ENDPOINT` - エンドポイント（例: `storage.googleapis.com`）
- `S3_ACCESS_KEY` - アクセスキー
- `S3_SECRET_KEY` - シークレットキー
- `S3_BUCKET` - バケット名
- `S3_USE_SSL` - SSL使用（`true` / `false`）

### ローカル開発（MinIO）

```sh
make test  # MinIO起動 + テスト実行（Docker Compose経由）
```

Docker Compose内でテスト実行することで、`minio:9000`で簡単にアクセス可能。

## フィード設定

フィードURLや出力設定は`feeds.json`でGit管理：

```json
{
  "title": "RSS Yoriyori",
  "link": "https://example.com",
  "output_file": "feed.xml",
  "max_items": 100,
  "max_items_per_feed": 10,
  "max_age_days": 14,
  "feeds": [
    "https://example.com/feed.xml",
    { "url": "https://github.com/org/repo/releases.atom", "prefix": "[releases]" }
  ]
}
```

### feeds配列の形式

| 形式 | prefix | 結果 |
|------|--------|------|
| `"https://..."` | フィードタイトル | `[Feed Title] Article` |
| `{ "url": "...", "prefix": "[Custom]" }` | カスタム | `[Custom] Article` |
| `{ "url": "...", "prefix": "" }` | なし | `Article` |

## HTTPエンドポイント

- `GET /health` - ヘルスチェック
- `GET /feed.xml` - 集約済みフィード配信（ストレージから取得）
- `POST /aggregate` - フィード取得・統合・保存

## 本番環境

- Cloud Run: `https://rss-yoriyori-hpos2m2qia-an.a.run.app`
- カスタムドメイン: `https://rss-yoriyori.lacolaco.dev`
- Scheduler: 10分毎に `/aggregate` 実行

