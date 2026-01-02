# CLAUDE.md

## 原則

### t_wada style TDD

**このプロジェクトでは機能追加・変更時にt_wadaスタイルのTDDを必ず適用する。例外なし。**

1. **RED**: 失敗するテストを先に書く（実装コードより先にテスト）
2. **GREEN**: テストを通す最小限の実装（それ以上書かない）
3. **REFACTOR**: テストが通る状態を維持しながらリファクタリング

ユーザーが実装する場合:
- Claudeはスキャフォールディング（ファイル特定、TODO(human)配置）のみ
- テスト・実装コードはユーザーが書く
- RED/GREEN/REFACTORの各フェーズはユーザーの報告を待つ
- 「TDDでやりますか？」と聞かない（t_wada TDDは前提）

### 作業前確認

作業前に「何をどうするか」を宣言し、ユーザーの確認を得てから実行する。

### 確認不要事項

- TDDの適用（確認せず適用する）

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
  "feeds": [
    "https://example.com/feed.xml"
  ]
}
```

## HTTPエンドポイント

- `GET /health` - ヘルスチェック
- `GET /feed.xml` - 集約済みフィード配信（ストレージから取得）
- `POST /aggregate` - フィード取得・統合・保存

## 本番環境

- Cloud Run: `https://rss-yoriyori-hpos2m2qia-an.a.run.app`
- カスタムドメイン: `https://rss-yoriyori.lacolaco.dev`
- Scheduler: 毎時0分に `/aggregate` 実行

