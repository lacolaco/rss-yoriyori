// test_helper.gleam - テスト用ヘルパー関数
//
// FeedItem/Feed のビルダー関数を提供してボイラープレートを削減

import birl
import feed/date.{type Time}
import feed/types.{type Feed, type FeedItem, Feed, FeedItem}
import gleam/option.{type Option, None, Some}

// ----------------------------------------------------------------------------
// FeedItem ビルダー
// ----------------------------------------------------------------------------

/// デフォルトのFeedItemを変換関数で加工して返す
///
/// 例:
///   item(fn(i) { i })  // デフォルトのまま
///   item(fn(i) { FeedItem(..i, title: "Custom") })  // タイトルを上書き
///   item(fn(i) { FeedItem(..i, title: "X", pub_date: Some(date)) })  // 複数フィールド
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

// ----------------------------------------------------------------------------
// Feed ビルダー
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// 日付ヘルパー
// ----------------------------------------------------------------------------

/// ISO 8601文字列をパースしてTimeを返す
pub fn date(date_str: String) -> Time {
  let assert Ok(d) = birl.parse(date_str)
  d
}

/// ISO 8601文字列をパースしてSome(Time)を返す
pub fn some_date(date_str: String) -> Option(Time) {
  Some(date(date_str))
}
