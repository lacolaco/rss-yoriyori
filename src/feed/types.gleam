// feed/types.gleam - RSSフィードの型定義
//
// RSS 2.0 / Atom フィードを表現する型

import birl.{type Time}
import gleam/option.{type Option}

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

/// フィードソース設定
pub type FeedSource {
  FeedSource(url: String, name: Option(String))
}
