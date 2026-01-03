// config.gleam - アプリケーション設定
//
// 起動時に1回だけ読み込む
// - フィード設定: feeds.json（Gitで管理）
// - ストレージ: 環境変数

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import simplifile
import storage/s3

/// フィード設定ファイルのパス
const feeds_file = "feeds.json"

/// フィードソース（URLとオプションのprefix）
pub type FeedSource {
  FeedSource(url: String, prefix: Option(String))
}

/// フィード設定（feeds.jsonから読み込み）
pub type FeedConfig {
  FeedConfig(
    title: String,
    link: String,
    output_file: String,
    max_items: Int,
    max_items_per_feed: Int,
    max_age_days: Int,
    feed_sources: List(FeedSource),
  )
}

/// アプリケーション設定
pub type Config {
  Config(feed: FeedConfig, storage: s3.StorageConfig)
}

/// 設定を読み込む
pub fn load() -> Result(Config, String) {
  use feed <- result.try(load_feed_config())
  use storage <- result.try(s3.config_from_env())

  Ok(Config(feed: feed, storage: storage))
}

/// feeds.jsonからフィード設定を読み込む
fn load_feed_config() -> Result(FeedConfig, String) {
  use content <- result.try(
    simplifile.read(feeds_file)
    |> result.replace_error("Failed to read " <> feeds_file),
  )

  let decoder = {
    use title <- decode.field("title", decode.string)
    use link <- decode.field("link", decode.string)
    use output_file <- decode.field("output_file", decode.string)
    use max_items <- decode.field("max_items", decode.int)
    use max_items_per_feed <- decode.field("max_items_per_feed", decode.int)
    use max_age_days <- decode.field("max_age_days", decode.int)
    use feed_sources <- decode.field(
      "feeds",
      decode.list(feed_source_decoder()),
    )
    decode.success(FeedConfig(
      title: title,
      link: link,
      output_file: output_file,
      max_items: max_items,
      max_items_per_feed: max_items_per_feed,
      max_age_days: max_age_days,
      feed_sources: feed_sources,
    ))
  }

  json.parse(content, decoder)
  |> result.replace_error("Failed to parse " <> feeds_file)
}

/// FeedSourceのデコーダー（文字列またはオブジェクト）
pub fn feed_source_decoder() -> decode.Decoder(FeedSource) {
  // 文字列の場合: URLのみ、prefix=None
  let string_decoder =
    decode.string
    |> decode.map(fn(url) { FeedSource(url: url, prefix: None) })

  // オブジェクトの場合: url必須、prefixオプション
  let object_decoder = {
    use url <- decode.field("url", decode.string)
    use prefix <- decode.optional_field(
      "prefix",
      None,
      decode.map(decode.string, Some),
    )
    decode.success(FeedSource(url: url, prefix: prefix))
  }

  decode.one_of(string_decoder, [object_decoder])
}
