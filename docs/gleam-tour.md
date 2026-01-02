# Gleam言語ツアー

このドキュメントでは、rss-yoriyoriプロジェクトの実際のコードを題材に、Gleam言語の基本的な構文と言語機能を学びます。

## 目次

1. [基本構文](#基本構文)
2. [カスタム型](#カスタム型)
3. [パターンマッチング](#パターンマッチング)
4. [Result型とエラー処理](#result型とエラー処理)
5. [パイプ演算子](#パイプ演算子)
6. [useキーワード](#useキーワード)
7. [Option型](#option型)
8. [リスト操作](#リスト操作)
9. [テスト](#テスト)

---

## 基本構文

### モジュールとインポート

Gleamのファイルは1つのモジュールに対応します。他のモジュールの機能を使うにはインポートが必要です。

```gleam
// src/rss_yoriyori.gleam より

import config                    // モジュール全体をインポート
import gleam/int                 // 標準ライブラリ
import gleam/result
import router
```

特定の型や関数だけをインポートすることもできます：

```gleam
// src/feed/types.gleam より

import birl.{type Time}              // 型のみをインポート
import gleam/option.{type Option}    // type キーワードで型を指定
```

```gleam
// src/feed/aggregator.gleam より

import gleam/option.{None, Some}     // コンストラクタをインポート
```

### const と let

- `const`: モジュールトップレベルで使用。コンパイル時定数（リテラルのみ）
- `let`: 関数内で使用。実行時の値束縛（再代入不可）

```gleam
// src/rss_yoriyori.gleam より

const default_port = 8080  // コンパイル時定数

pub fn main() -> Nil {
  let port =                // 実行時の値束縛
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(default_port)
  // ...
}
```

```gleam
// src/config.gleam より

const feeds_file = "feeds.json"  // 文字列リテラルもOK
```

### 関数定義

関数は `fn` キーワードで定義します。公開するには `pub` を付けます。

```gleam
// src/router.gleam より

/// GET /health（ドキュメントコメント）
fn health() -> Response {           // プライベート関数
  wisp.ok()
  |> wisp.string_body("OK")
}

/// HTTPリクエストを受け取り、適切なレスポンスを返す
pub fn handle_request(req: Request, config: Config) -> Response {  // 公開関数
  // ...
}
```

### 文字列連結

文字列連結には `<>` 演算子を使います。

```gleam
// src/feed/aggregator.gleam より

Error(FetchError("Invalid URL: " <> url))
Error(FetchError("HTTP " <> string.inspect(status) <> ": " <> url))
```

---

## カスタム型

Gleamでは `type` キーワードでカスタム型（代数的データ型）を定義します。

### レコード型（単一バリアント）

フィールドを持つ構造体のような型：

```gleam
// src/feed/types.gleam より

/// フィードアイテム（記事）
pub type FeedItem {
  FeedItem(
    title: String,
    link: String,
    pub_date: Option(Time),
    description: Option(String),
  )
}

/// パース済みフィード
pub type Feed {
  Feed(
    title: String,
    link: String,
    description: Option(String),
    items: List(FeedItem),
  )
}
```

使用例：

```gleam
// src/feed/aggregator.gleam より

Feed(title: title, link: link, description: None, items: items)
```

フィールドへのアクセス：

```gleam
feed.title      // "Example Blog"
feed.items      // [FeedItem(...), ...]
```

### 列挙型（複数バリアント）

複数のケースを持つ型：

```gleam
// src/feed/parser.gleam より

/// パースエラー
pub type ParseError {
  InvalidXml(String)        // 引数を持つバリアント
  UnsupportedFormat(String)
}
```

```gleam
// src/storage/s3.gleam より

/// ストレージ操作の結果
pub type StorageError {
  ConnectionError(String)
  UploadError(String)
  NotFoundError             // 引数なしのバリアント
}
```

---

## パターンマッチング

Gleamでは `case` 式でパターンマッチングを行います。

### 基本的なcase式

```gleam
// src/router.gleam より

pub fn handle_request(req: Request, config: Config) -> Response {
  case req.method, wisp.path_segments(req) {
    Get, ["health"] -> health()
    _, ["health"] -> wisp.method_not_allowed([Get])
    Get, ["feed.xml"] -> serve_feed(config)
    _, ["feed.xml"] -> wisp.method_not_allowed([Get])
    Post, ["aggregate"] -> aggregate(config)
    _, ["aggregate"] -> wisp.method_not_allowed([Post])
    _, _ -> wisp.not_found()  // ワイルドカード
  }
}
```

### カスタム型のパターンマッチング

```gleam
// src/router.gleam より

fn aggregate_error_to_string(e: aggregator.AggregateError) -> String {
  case e {
    aggregator.FetchError(msg) -> "Fetch error: " <> msg
    aggregator.ParseError(msg) -> "Parse error: " <> msg
    aggregator.StorageError(msg) -> "Storage error: " <> msg
  }
}
```

### ネストしたパターンマッチング

```gleam
// src/feed/aggregator.gleam より

fn sort_by_date_desc(items: List(FeedItem)) -> List(FeedItem) {
  list.sort(items, fn(a, b) {
    case a.pub_date, b.pub_date {
      Some(date_a), Some(date_b) -> date.compare_desc(date_a, date_b)
      Some(_), None -> order.Lt    // Someの中身は使わない
      None, Some(_) -> order.Gt
      None, None -> order.Eq
    }
  })
}
```

---

## Result型とエラー処理

Gleamには例外がありません。代わりに `Result(value, error)` 型を使います。

### Result型の基本

```gleam
// Result は2つのバリアントを持つ
type Result(value, error) {
  Ok(value)
  Error(error)
}
```

### パターンマッチングでの処理

```gleam
// src/router.gleam より

fn serve_feed(config: Config) -> Response {
  case s3.get_object(config.storage, config.feed.output_file) {
    Ok(content) ->
      wisp.ok()
      |> wisp.set_header("content-type", "application/rss+xml; charset=utf-8")
      |> wisp.string_body(content)
    Error(s3.NotFoundError) -> wisp.not_found()
    Error(_) -> wisp.internal_server_error()
  }
}
```

### result.try でチェーン

`result.try` は Ok の場合のみ次の処理を実行し、Error はそのまま伝播します。

```gleam
// src/storage/s3.gleam より

pub fn config_from_env() -> Result(StorageConfig, String) {
  use endpoint <- result.try(
    envoy.get("S3_ENDPOINT")
    |> result.replace_error("S3_ENDPOINT is not set"),
  )
  use access_key <- result.try(
    envoy.get("S3_ACCESS_KEY")
    |> result.replace_error("S3_ACCESS_KEY is not set"),
  )
  // ... 続く
  Ok(StorageConfig(...))
}
```

### result.map と result.unwrap

```gleam
// src/storage/s3.gleam より

let use_ssl =
  envoy.get("S3_USE_SSL")
  |> result.map(fn(val) { string.lowercase(val) == "true" })  // Ok時のみ変換
  |> result.unwrap(False)  // デフォルト値で取り出し
```

---

## パイプ演算子

`|>` は左辺の結果を右辺の関数の**第1引数**に渡します。

### 基本的な使い方

```gleam
// src/router.gleam より

wisp.ok()
|> wisp.set_header("content-type", "application/rss+xml")
|> wisp.string_body(rss_xml)

// これは以下と同じ
wisp.string_body(
  wisp.set_header(wisp.ok(), "content-type", "application/rss+xml"),
  rss_xml
)
```

### チェーンの例

```gleam
// src/feed/aggregator.gleam より

let items =
  feeds
  |> list.flat_map(fn(feed) { feed.items })  // 全フィードのアイテムを結合
  |> sort_by_date_desc                        // 日付でソート
  |> list.take(max_items)                     // 先頭N件を取得
```

### ビルダーパターン

```gleam
// src/rss_yoriyori.gleam より

let assert Ok(_) =
  wisp_mist.handler(handler, secret_key_base)
  |> mist.new
  |> mist.bind("0.0.0.0")
  |> mist.port(port)
  |> mist.start
```

---

## useキーワード

`use` はコールバック地獄を解消する構文糖衣です。

### useなしの場合（ネストが深くなる）

```gleam
result.try(envoy.get("S3_ENDPOINT"), fn(endpoint) {
  result.try(envoy.get("S3_ACCESS_KEY"), fn(access_key) {
    Ok(Config(endpoint, access_key))
  })
})
```

### useありの場合（フラットに書ける）

```gleam
// src/config.gleam より

pub fn load() -> Result(Config, String) {
  use feed <- result.try(load_feed_config())
  use storage <- result.try(s3.config_from_env())

  Ok(Config(feed: feed, storage: storage))
}
```

`use x <- f(...)` は `f(..., fn(x) { 残りのコード })` と等価です。

### JSONデコーダーでのuse

```gleam
// src/config.gleam より

let decoder = {
  use title <- decode.field("title", decode.string)
  use link <- decode.field("link", decode.string)
  use output_file <- decode.field("output_file", decode.string)
  use max_items <- decode.field("max_items", decode.int)
  use feed_urls <- decode.field("feeds", decode.list(decode.string))
  decode.success(FeedConfig(
    title: title,
    link: link,
    output_file: output_file,
    max_items: max_items,
    feed_urls: feed_urls,
  ))
}
```

---

## Option型

値が存在しない可能性を表すには `Option` 型を使います。

### 定義

```gleam
// gleam/option モジュールで定義
type Option(a) {
  Some(a)
  None
}
```

### 使用例

```gleam
// src/feed/types.gleam より

pub type FeedItem {
  FeedItem(
    title: String,
    link: String,
    pub_date: Option(Time),        // 日付がない場合もある
    description: Option(String),   // 説明がない場合もある
  )
}
```

### パターンマッチング

```gleam
// src/feed/aggregator.gleam より

case a.pub_date, b.pub_date {
  Some(date_a), Some(date_b) -> date.compare_desc(date_a, date_b)
  Some(_), None -> order.Lt
  None, Some(_) -> order.Gt
  None, None -> order.Eq
}
```

---

## リスト操作

Gleamのリストはイミュータブルな連結リストです。

### 基本操作

```gleam
// src/feed/aggregator.gleam より

feeds
|> list.flat_map(fn(feed) { feed.items })  // 各フィードのitemsを結合
|> list.take(max_items)                     // 先頭N件
```

### filter_map（フィルタと変換を同時に）

```gleam
// src/feed/aggregator.gleam より

let feeds =
  feed_config.feed_urls
  |> list.filter_map(fn(url) {
    case fetch_and_parse(url) {
      Ok(feed) -> Ok(feed)    // Ok -> 結果に含める
      Error(_) -> Error(Nil)  // Error -> スキップ
    }
  })
```

### sort（カスタム比較関数）

```gleam
// src/feed/aggregator.gleam より

list.sort(items, fn(a, b) {
  case a.pub_date, b.pub_date {
    Some(date_a), Some(date_b) -> date.compare_desc(date_a, date_b)
    // ...
  }
})
```

---

## テスト

Gleamでは `gleeunit` を使ってテストを書きます。

### テスト関数の命名

関数名が `_test` で終わるとテストとして認識されます。

```gleam
// test/feed_parser_test.gleam より

pub fn parse_rss_channel_metadata_test() {
  let assert Ok(feed) = parser.parse(rss_sample)

  assert feed.title == "Example Blog"
  assert feed.link == "https://example.com"
}
```

### let assert（リファータブル・パターンマッチ）

パターンマッチが失敗したらクラッシュする構文。テストで「この値は絶対Okのはず」という前提を表明するのに便利です。

```gleam
// test/feed_parser_test.gleam より

pub fn parse_rss_items_test() {
  let assert Ok(feed) = parser.parse(rss_sample)

  // 2つのアイテムがあるはず
  let assert [first, second] = feed.items

  assert first.title == "First Post"
  assert first.link == "https://example.com/first"
}
```

### 複数行文字列リテラル

テストデータとして便利：

```gleam
// test/feed_parser_test.gleam より

const rss_sample = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<rss version=\"2.0\">
  <channel>
    <title>Example Blog</title>
    <link>https://example.com</link>
    ...
  </channel>
</rss>"
```

### テストの実行

```sh
make test  # Docker Compose経由で実行（MinIO統合テスト含む）
```

---

## 無名関数とクロージャ

### 無名関数

```gleam
// src/rss_yoriyori.gleam より

let handler = fn(req) { router.handle_request(req, app_config) }
```

### list操作での無名関数

```gleam
// src/feed/aggregator.gleam より

feeds
|> list.flat_map(fn(feed) { feed.items })
```

```gleam
// src/storage/s3.gleam より

envoy.get("S3_USE_SSL")
|> result.map(fn(val) { string.lowercase(val) == "true" })
```

---

## まとめ

| 概念 | 例 |
|------|-----|
| モジュール | `import gleam/result` |
| 定数 | `const port = 8080` |
| 変数束縛 | `let x = 5` |
| 関数定義 | `pub fn foo() -> Int { 42 }` |
| カスタム型 | `pub type Error { NotFound, Timeout }` |
| パターンマッチ | `case x { Ok(v) -> v, Error(_) -> 0 }` |
| パイプ | `x |> f() |> g()` |
| use | `use x <- result.try(...)` |
| Option | `Some(value)` / `None` |
| Result | `Ok(value)` / `Error(reason)` |
| let assert | `let assert Ok(x) = maybe_ok` |

より詳しい情報は [Gleam公式ドキュメント](https://gleam.run/documentation/) を参照してください。
