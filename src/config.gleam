// config.gleam - アプリケーション設定
//
// 起動時に1回だけ読み込む
// - フィード設定: feeds.json（Gitで管理）
// - ストレージ: 環境変数

import gleam/dynamic/decode
import gleam/json
import gleam/result
import simplifile
import storage/s3

/// フィード設定ファイルのパス
const feeds_file = "feeds.json"

/// フィード設定（feeds.jsonから読み込み）
pub type FeedConfig {
  FeedConfig(
    title: String,
    link: String,
    output_file: String,
    max_items: Int,
    max_items_per_feed: Int,
    feed_urls: List(String),
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
    use feed_urls <- decode.field("feeds", decode.list(decode.string))
    decode.success(FeedConfig(
      title: title,
      link: link,
      output_file: output_file,
      max_items: max_items,
      max_items_per_feed: max_items_per_feed,
      feed_urls: feed_urls,
    ))
  }

  json.parse(content, decoder)
  |> result.replace_error("Failed to parse " <> feeds_file)
}
