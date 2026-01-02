# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rss_yoriyori is a Gleam library/application. Gleam is a type-safe functional programming language that compiles to Erlang and JavaScript.

## Build Commands

```sh
gleam build      # Compile the project
gleam run        # Run the project
make test        # テスト実行（必須：Docker Compose経由）
gleam docs build # Generate documentation
```

## Testing

**重要: テストは必ず `make test` で実行すること。`gleam test` は使わない。**

理由：
- storage_testはMinIOが必要
- Docker Compose経由で実行することで、MinIOが自動起動する
- `gleam test` では環境変数がなく、storage_testが失敗する

Tests are located in `test/` and use the gleeunit testing framework. Test functions must end with `_test` suffix to be discovered and run.

## Project Structure

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

## Gleam Language Notes

- Gleam uses `assert` for assertions in tests
- String concatenation uses `<>`
- All functions must have explicit return types
- Pattern matching is the primary control flow mechanism

### 命名規則

- 変数・関数: `snake_case`（例: `default_port`, `handle_request`）
- 型: `PascalCase`（例: `Result`, `FeedItem`）
- モジュール: `snake_case`（例: `gleam/int`, `router`）

### let vs const

- `const`: モジュールトップレベル、コンパイル時定数（リテラルのみ）
- `let`: 関数内、実行時束縛（再代入不可、イミュータブル）

### パイプ演算子 `|>`

左辺の結果を右辺の関数の**第1引数**に渡す：

```gleam
// これは
wisp.ok()
|> wisp.set_header("content-type", "application/rss+xml")
|> wisp.string_body(rss_xml)

// これと同じ
wisp.string_body(
  wisp.set_header(wisp.ok(), "content-type", "application/rss+xml"),
  rss_xml
)
```

制約：
- 右辺は必ず関数呼び出し（括弧必須）: `|> func()` ○ / `|> func` ✗
- 第1引数の型が一致しないとコンパイルエラー
- 引数0個の関数にはパイプできない

### Result型のチェーン

```gleam
envoy.get("PORT")           // Result(String, Nil)
|> result.try(int.parse)    // Ok → 変換、Error → 伝播
|> result.unwrap(8080)      // デフォルト値で取り出し
```

- `result.try`: Okの場合のみ次の関数を適用（旧名: `result.then`は非推奨）
- `result.unwrap`: デフォルト値付きで値を取り出す
- `result.replace_error`: エラー型を変換

### useキーワード（継続渡しの構文糖衣）

`use`は「コールバック地獄」を解消する構文糖衣：

```gleam
// use なし（ネストが深くなる）
result.try(envoy.get("S3_ENDPOINT"), fn(endpoint) {
  result.try(envoy.get("S3_ACCESS_KEY"), fn(access_key) {
    Ok(Config(endpoint, access_key))
  })
})

// use あり（フラットに書ける）
use endpoint <- result.try(envoy.get("S3_ENDPOINT"))
use access_key <- result.try(envoy.get("S3_ACCESS_KEY"))
Ok(Config(endpoint, access_key))
```

- `use x <- f(...)` は `f(..., fn(x) { 残りのコード })` と等価
- Rustの`?`演算子やHaskellの`do`記法に相当

### result.try vs result.map

```gleam
// result.map: 失敗しない変換処理
result.map(Ok(5), fn(x) { x * 2 })  // Ok(10)

// result.try: 失敗する可能性がある変換処理
result.try(Ok(5), fn(x) { Ok(x * 2) })  // Ok(10)
result.try(Ok(5), fn(x) { Error("oops") })  // Error("oops")
```

### let assert（リファータブル・パターンマッチ）

パターンマッチが失敗したらクラッシュする構文：

```gleam
// 通常の let - 必ず成功するパターンのみ
let x = 5  // OK
let Ok(x) = result  // コンパイルエラー

// let assert - 失敗したらクラッシュ
let assert Ok(date) = birl.parse("2025-01-01T12:00:00Z")
```

テストで「この値は絶対Okのはず」という前提を表明するのに便利。

### Option型と日時

Gleam標準ライブラリに日時型はない。`birl`パッケージを使用：

```gleam
import birl
import gleam/option.{type Option, Some, None}

// 現在時刻
let now = birl.now()

// パース
let assert Ok(time) = birl.parse("2025-01-01T12:00:00Z")

// Option型
let maybe_date: Option(birl.Time) = Some(now)
let no_date: Option(birl.Time) = None
```

### カスタム型（代数的データ型）

`type`で独自の型を定義。enumとstructの区別はない：

```gleam
// enum的（複数バリアント）
pub type ParseError {
  InvalidXml(String)
  UnsupportedFormat(String)
}

// struct的（単一バリアント）
pub type FeedItem {
  FeedItem(
    title: String,
    link: String,
    pub_date: Option(Time),
  )
}

// 使用
let item = FeedItem(title: "Hello", link: "https://...", pub_date: None)
item.title  // "Hello"
```

### テストのコロケーション

- gleeunitは`test/`ディレクトリのみ検索（ハードコード）
- `src/`内のテストを使いたい場合は`test/`から再エクスポート、またはGlacierを使用

### wispハンドラーのテスト

`wisp/simulate`モジュールを使用：

```gleam
import gleam/http
import wisp/simulate
import router

pub fn my_endpoint_test() {
  // リクエスト作成
  let request = simulate.request(http.Post, "/path")

  // ハンドラー呼び出し
  let response = router.handle_request(request)

  // アサーション
  assert response.status == 200
  let body = simulate.read_body(response)
  assert string.contains(body, "expected")
}
```

- `simulate.request(method, path)`: テスト用リクエスト生成
- `simulate.read_body(response)`: レスポンスボディを文字列で取得
- `simulate.string_body(content)`: リクエストにボディを設定

## Docker

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
  "feeds": [
    "https://example.com/feed.xml"
  ]
}
```

### JSONデコーダー（ブロック式 + use）

```gleam
let decoder = {
  use title <- decode.field("title", decode.string)
  use max_items <- decode.field("max_items", decode.int)
  decode.success(Config(title: title, max_items: max_items))
}

json.parse(content, decoder)
```

- `{ }` はブロック式（最後の式の値を返す）
- `use`で継続渡しをフラットに書ける
- `decode.success(value)`で最終値を返す

## HTTPエンドポイント

- `GET /health` - ヘルスチェック
- `GET /feed.xml` - 集約済みフィード配信（ストレージから取得）
- `POST /aggregate` - フィード取得・統合・保存

## 本番環境

- Cloud Run: `https://rss-yoriyori-hpos2m2qia-an.a.run.app`
- カスタムドメイン: `https://rss-yoriyori.lacolaco.dev`
- Scheduler: 毎時0分に `/aggregate` 実行
