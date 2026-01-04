# Gleam言語ツアー

このドキュメントでは、rss-yoriyoriプロジェクトの実際のコードを題材に、Gleam言語の基本的な構文と言語機能を学びます。

## 目次

1. [基本構文](#基本構文)
2. [タプル型](#タプル型)
3. [カスタム型](#カスタム型)
4. [パターンマッチング](#パターンマッチング)
5. [Result型とエラー処理](#result型とエラー処理)
6. [パイプ演算子](#パイプ演算子)
7. [useキーワード](#useキーワード)
8. [Option型](#option型)
9. [リスト操作](#リスト操作)
10. [テスト](#テスト)
11. [レコード更新構文](#レコード更新構文)
12. [パターンマッチでのガード](#パターンマッチでのガード)
13. [再帰と文字列処理](#再帰と文字列処理)
14. [高階関数によるビルダーパターン](#高階関数によるビルダーパターン)
15. [プラットフォーム固有の機能](#プラットフォーム固有の機能)

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

### 命名規則

- 変数・関数: `snake_case`（例: `default_port`, `handle_request`）
- 型: `PascalCase`（例: `Result`, `FeedItem`）
- モジュール: `snake_case`（例: `gleam/int`, `router`）

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

## タプル型

タプルは固定長で異なる型の値をまとめて扱う型です。`#(...)`構文で表現します。

```gleam
#(String, String)       // 2つのStringを持つタプル型
#(String, Int, Bool)    // 3つの異なる型を持つタプル型

#("hello", "world")     // 値の例
#("name", 42, True)     // 値の例
```

### パターンマッチでアクセス

タプルの要素はパターンマッチで分解して取り出します。

```gleam
let pair = #("key", "value")
let #(first, second) = pair
// first = "key", second = "value"
```

### 関数の戻り値での使用

```gleam
// src/feed/html.gleam より

case string.pop_grapheme(input) {
  Ok(#(char, rest)) -> ...  // char="a", rest="bc"
  Error(_) -> ...
}
```

`string.pop_grapheme`は`Result(#(String, String), Nil)`を返します。成功時は先頭文字と残りの文字列のタプルです。

### タプル vs レコード vs リスト

| 型 | 用途 |
|----|------|
| タプル `#(a, b)` | 少数の異なる型をまとめる（2-3要素） |
| レコード `Foo(x: a, y: b)` | 名前付きフィールドで意味を明確に |
| リスト `List(a)` | 同じ型の可変長コレクション |

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

### wispハンドラーのテスト

`wisp/simulate`モジュールを使用：

```gleam
// test/router_test.gleam

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

### テストのコロケーション

- gleeunitは`test/`ディレクトリのみ検索（ハードコード）
- `src/`内のテストを使いたい場合は`test/`から再エクスポート、またはGlacierを使用

---

## レコード更新構文

既存のレコードから一部のフィールドだけを変更した新しいレコードを作成できます。

```gleam
// src/feed/aggregator.gleam より

// タイトルだけを変更した新しいFeedItemを作成
FeedItem(..item, title: strip_html_tags(item.title))

// これは以下と同じ（冗長）
FeedItem(
  title: strip_html_tags(item.title),
  link: item.link,
  description: item.description,
  pub_date: item.pub_date,
)
```

`..item` で元のレコードの全フィールドをコピーし、その後に指定したフィールドだけを上書きします。

---

## パターンマッチでのガード

`case`式でパターンに加えて条件（ガード）を指定できます。

```gleam
// src/feed/html.gleam より

fn strip_tags_loop(input: String, acc: String, in_tag: Bool) -> String {
  case string.pop_grapheme(input) {
    Error(_) -> acc
    Ok(#("<", rest)) -> strip_tags_loop(rest, acc, True)
    Ok(#(">", rest)) -> strip_tags_loop(rest, acc, False)
    Ok(#(_, rest)) if in_tag -> strip_tags_loop(rest, acc, True)  // ガード
    Ok(#(char, rest)) -> strip_tags_loop(rest, acc <> char, False)
  }
}
```

`if in_tag` がガードです。パターンがマッチし、かつガードが`True`の場合のみそのブランチが実行されます。

---

## 再帰と文字列処理

Gleamにはループ構文がないため、繰り返し処理は再帰で実装します。

### string.pop_grapheme

文字列から先頭の1文字を取り出します。

```gleam
string.pop_grapheme("hello")  // Ok(#("h", "ello"))
string.pop_grapheme("")       // Error(Nil)
```

### 再帰ループの例

HTMLタグを除去する処理：

```gleam
// src/feed/html.gleam より

pub fn strip_tags(html: String) -> String {
  strip_tags_loop(html, "", False)
}

fn strip_tags_loop(input: String, acc: String, in_tag: Bool) -> String {
  case string.pop_grapheme(input) {
    Error(_) -> acc                                              // 終了条件
    Ok(#("<", rest)) -> strip_tags_loop(rest, acc, True)         // タグ開始
    Ok(#(">", rest)) -> strip_tags_loop(rest, acc, False)        // タグ終了
    Ok(#(_, rest)) if in_tag -> strip_tags_loop(rest, acc, True) // タグ内をスキップ
    Ok(#(char, rest)) -> strip_tags_loop(rest, acc <> char, False) // テキストを蓄積
  }
}
```

パターン:
- `acc`: アキュムレータ（結果を蓄積）
- `in_tag`: 状態を表すフラグ
- 終了条件で`acc`を返す

---

## 高階関数によるビルダーパターン

テストなどでオブジェクトを作成する際、デフォルト値を持つファクトリ関数に変換関数を渡すパターンです。

### 基本形

```gleam
// test/test_helper.gleam より

/// デフォルトのFeedItemを変換関数で加工して返す
pub fn item(f: fn(FeedItem) -> FeedItem) -> FeedItem {
  let base =
    FeedItem(
      title: "Test Item",
      link: "https://example.com/item",
      description: None,
      pub_date: None,
    )
  f(base)
}

/// デフォルトのFeedを変換関数で加工して返す
pub fn feed(f: fn(Feed) -> Feed) -> Feed {
  let base =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: None,
      items: [],
    )
  f(base)
}
```

### 使用例

```gleam
// test/aggregator_test.gleam より

// デフォルトのまま使う
item(fn(i) { i })

// タイトルだけ上書き
item(fn(i) { FeedItem(..i, title: "Custom Title") })

// 複数フィールドを上書き
item(fn(i) {
  FeedItem(..i, title: "Article", pub_date: some_date("2025-01-01T12:00:00Z"))
})

// feedの中にitemを含める
feed(fn(f) {
  Feed(..f, items: [
    item(fn(i) { FeedItem(..i, title: "Article 1") }),
    item(fn(i) { FeedItem(..i, title: "Article 2") }),
  ])
})
```

### なぜこのパターンが有効か

1. **柔軟性**: どのフィールドの組み合わせでも上書き可能
2. **簡潔さ**: テストごとに必要なフィールドだけを指定
3. **型安全**: レコード更新構文により存在しないフィールドはコンパイルエラー
4. **合成可能**: ネストしたオブジェクトも自然に作成できる

### 従来のアプローチとの比較

```gleam
// ❌ 複数のファクトリ関数が必要
item_with_title(title)
item_with_date(title, date)
item_with_title_and_date(title, date)
item_with_description(title, desc)
// ... 組み合わせ爆発

// ✅ 高階関数パターン - 1つの関数で全パターン対応
item(fn(i) { FeedItem(..i, title: t) })
item(fn(i) { FeedItem(..i, title: t, pub_date: d) })
item(fn(i) { FeedItem(..i, title: t, description: desc) })
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

## プラットフォーム固有の機能

### Gleam標準ライブラリの設計方針

GleamはErlang VMとJavaScriptの両方にコンパイルされる。そのため、標準ライブラリ（`gleam_stdlib`）には**両ターゲットで動作する機能のみ**含まれる。

**標準ライブラリに含まれないもの:**
- ファイルI/O
- ネットワーク
- プロセス管理
- 時刻取得

これらはプラットフォーム固有のライブラリで提供される：

| 機能 | ライブラリ | 対象 |
|------|-----------|------|
| ファイルI/O | `simplifile` | Erlang |
| プロセス・Actor | `gleam_erlang` | Erlang |
| HTTPクライアント | `gleam_httpc` | Erlang |
| Promise | `gleam_javascript` | JavaScript |

### ファイル読み込み（simplifile）

このプロジェクトでは`feeds.json`の読み込みに使用：

```gleam
// src/config.gleam より

import simplifile

const feeds_file = "feeds.json"

fn load_feed_config() -> Result(FeedConfig, String) {
  use content <- result.try(
    simplifile.read(feeds_file)
    |> result.replace_error("Failed to read " <> feeds_file),
  )
  // JSONパース処理...
}
```

主な関数：

```gleam
// ファイル読み込み
simplifile.read("path/to/file")  // -> Result(String, FileError)

// ファイル書き込み
simplifile.write("path/to/file", content)  // -> Result(Nil, FileError)

// ファイル存在確認
simplifile.is_file("path/to/file")  // -> Result(Bool, FileError)
```

### なぜ標準ライブラリに含めないのか

1. **クロスプラットフォーム互換性**: ErlangとJavaScriptでAPIが全く異なる
2. **依存の明確化**: 使用するプラットフォームを`gleam.toml`で明示
3. **軽量な標準ライブラリ**: 必要なものだけを依存に追加

---

## まとめ

| 概念 | 例 |
|------|-----|
| モジュール | `import gleam/result` |
| 定数 | `const port = 8080` |
| 変数束縛 | `let x = 5` |
| タプル | `#(a, b)` / `let #(x, y) = pair` |
| 関数定義 | `pub fn foo() -> Int { 42 }` |
| カスタム型 | `pub type Error { NotFound, Timeout }` |
| パターンマッチ | `case x { Ok(v) -> v, Error(_) -> 0 }` |
| パイプ | `x |> f() |> g()` |
| use | `use x <- result.try(...)` |
| Option | `Some(value)` / `None` |
| Result | `Ok(value)` / `Error(reason)` |
| let assert | `let assert Ok(x) = maybe_ok` |
| レコード更新 | `Foo(..old, field: new_value)` |
| ガード | `Ok(x) if x > 0 -> ...` |
| 再帰 | 終了条件 + 再帰呼び出し |
| ビルダーパターン | `item(fn(i) { Foo(..i, x: v) })` |

より詳しい情報は [Gleam公式ドキュメント](https://gleam.run/documentation/) を参照してください。
