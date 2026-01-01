// feed_types_test.gleam - フィード型のテスト

import birl
import feed/types.{Feed, FeedItem, FeedSource}
import gleam/option.{None, Some}

// ----------------------------------------------------------------------------
// FeedItem テスト
// ----------------------------------------------------------------------------

pub fn feed_item_can_be_created_test() {
  let item =
    FeedItem(
      title: "Test Article",
      link: "https://example.com/article",
      pub_date: None,
      description: Some("This is a test article"),
    )

  assert item.title == "Test Article"
  assert item.link == "https://example.com/article"
  assert item.pub_date == None
  assert item.description == Some("This is a test article")
}

pub fn feed_item_with_date_test() {
  let assert Ok(date) = birl.parse("2025-01-01T12:00:00Z")
  let item =
    FeedItem(
      title: "Article with date",
      link: "https://example.com",
      pub_date: Some(date),
      description: None,
    )

  assert item.pub_date != None
}

// ----------------------------------------------------------------------------
// Feed テスト
// ----------------------------------------------------------------------------

pub fn feed_can_be_created_test() {
  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com/feed",
      description: Some("A test RSS feed"),
      items: [],
    )

  assert feed.title == "Test Feed"
  assert feed.items == []
}

pub fn feed_with_items_test() {
  let item =
    FeedItem(
      title: "Article 1",
      link: "https://example.com/1",
      pub_date: None,
      description: None,
    )

  let feed =
    Feed(
      title: "Feed with items",
      link: "https://example.com",
      description: None,
      items: [item],
    )

  assert feed.items != []
}

// ----------------------------------------------------------------------------
// FeedSource テスト
// ----------------------------------------------------------------------------

pub fn feed_source_can_be_created_test() {
  let source = FeedSource(url: "https://example.com/feed.xml", name: None)

  assert source.url == "https://example.com/feed.xml"
  assert source.name == None
}

pub fn feed_source_with_name_test() {
  let source =
    FeedSource(url: "https://example.com/feed.xml", name: Some("Example Blog"))

  assert source.name == Some("Example Blog")
}
