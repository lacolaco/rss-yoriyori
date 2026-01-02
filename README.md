# rss-yoriyori

複数のRSS/Atomフィードを1つに集約するGleam製フィードアグリゲーター。

## 機能

- RSS 2.0 / Atom フィードの自動判定・パース
- 複数フィードの統合（日付降順ソート、件数制限）
- S3互換ストレージへの出力（GCS/MinIO対応）
- Cloud Scheduler による定期実行
- カスタムドメイン対応

## エンドポイント

| パス | メソッド | 説明 |
|------|----------|------|
| `/health` | GET | ヘルスチェック |
| `/feed.xml` | GET | 集約済みフィード取得 |
| `/aggregate` | POST | フィード更新実行 |

## 開発

### 前提条件

- [Docker](https://www.docker.com/)
- [Dev Containers](https://containers.dev/) 対応エディタ（VS Code推奨）

### ローカル開発

```sh
# devcontainer を起動後
make up      # ビルド＆起動
make logs    # ログ表示
make down    # 停止
```

### テスト

```sh
make test    # Docker Compose経由で実行（MinIO統合テスト含む）
```

> **注意**: `gleam test` ではなく `make test` を使用してください。MinIOが必要なテストがあります。

### コード品質

```sh
make build         # ビルド
make format-check  # フォーマットチェック
```

## 設定

### フィード設定（feeds.json）

```json
{
  "title": "RSS Yoriyori",
  "link": "https://example.com",
  "output_file": "feed.xml",
  "max_items": 100,
  "feeds": [
    "https://example.com/feed.xml",
    "https://another.com/rss"
  ]
}
```

### 環境変数

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `PORT` | HTTPサーバーポート | `8080` |
| `S3_ENDPOINT` | ストレージエンドポイント | `storage.googleapis.com` |
| `S3_ACCESS_KEY` | アクセスキー | - |
| `S3_SECRET_KEY` | シークレットキー | - |
| `S3_BUCKET` | バケット名 | `my-bucket` |
| `S3_USE_SSL` | SSL使用 | `true` / `false` |

## デプロイ

GitHub Actionsで自動デプロイ（mainブランチへのPR作成時）。

### インフラ構成

- **Cloud Run**: アプリケーション実行
- **Cloud Storage**: フィード保存（S3互換API）
- **Cloud Scheduler**: 定期実行（毎時）
- **Artifact Registry**: Dockerイメージ保存
- **Workload Identity Federation**: GitHub Actions認証

### 手動デプロイ

```sh
make plan    # Terraform plan確認
make deploy  # デプロイ（GitHub Actions経由推奨）
```

## アーキテクチャ

```
┌─────────────────┐     ┌─────────────────┐
│ Cloud Scheduler │────▶│    Cloud Run    │
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
           ┌───────────────┐         ┌───────────────┐
           │  外部フィード  │         │ Cloud Storage │
           │  (RSS/Atom)   │         │  (feed.xml)   │
           └───────────────┘         └───────────────┘
```

## ドキュメント

- [Gleam言語ツアー](docs/gleam-tour.md) - このプロジェクトのコードで学ぶGleam入門
- [CLAUDE.md](CLAUDE.md) - 開発ガイドライン

## ライセンス

MIT
