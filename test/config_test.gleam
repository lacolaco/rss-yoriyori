// config_test.gleam - 設定読み込みのテスト

import config
import gleam/json
import gleam/option.{None, Some}

// ----------------------------------------------------------------------------
// FeedSource デコーダーテスト
// ----------------------------------------------------------------------------

pub fn feed_source_string_url_decodes_with_no_prefix_test() {
  // 文字列URLの場合、prefix=Noneとして扱われる
  let json_string = "\"https://example.com/feed.xml\""

  let result = json.parse(json_string, config.feed_source_decoder())

  let assert Ok(source) = result
  assert source.url == "https://example.com/feed.xml"
  assert source.prefix == None
}

pub fn feed_source_object_format_decodes_with_prefix_test() {
  // オブジェクト形式でprefixが指定されている場合
  let json_string =
    "{\"url\": \"https://example.com/feed.xml\", \"prefix\": \"[Example]\"}"

  let result = json.parse(json_string, config.feed_source_decoder())

  let assert Ok(source) = result
  assert source.url == "https://example.com/feed.xml"
  assert source.prefix == Some("[Example]")
}

pub fn feed_source_object_format_without_prefix_decodes_as_none_test() {
  // オブジェクト形式でprefixがない場合、prefix=None
  let json_string = "{\"url\": \"https://example.com/feed.xml\"}"

  let result = json.parse(json_string, config.feed_source_decoder())

  let assert Ok(source) = result
  assert source.url == "https://example.com/feed.xml"
  assert source.prefix == None
}

pub fn feed_source_object_format_with_empty_prefix_test() {
  // オブジェクト形式でprefixが空文字列の場合
  let json_string =
    "{\"url\": \"https://example.com/feed.xml\", \"prefix\": \"\"}"

  let result = json.parse(json_string, config.feed_source_decoder())

  let assert Ok(source) = result
  assert source.url == "https://example.com/feed.xml"
  assert source.prefix == Some("")
}
