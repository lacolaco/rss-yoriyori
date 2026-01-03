// aggregator_test.gleam - フィード統合ロジックのテスト

import feed/aggregator
import feed/types.{Feed, FeedItem}
import gleam/list
import gleam/option.{None}
import gleam/string
import test_helper.{feed, item, some_date}

// ----------------------------------------------------------------------------
// merge_feeds テスト
// ----------------------------------------------------------------------------

pub fn merge_empty_feeds_test() {
  let result =
    aggregator.merge_feeds([], "Combined", "https://example.com", 100, 10, None)

  assert result.title == "Combined"
  assert result.link == "https://example.com"
  assert result.items == []
}

pub fn merge_single_feed_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [item(fn(i) { FeedItem(..i, title: "Article 1") })])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      None,
    )

  assert result.title == "Combined"
  assert list.length(result.items) == 1
  let assert [merged_item] = result.items
  assert merged_item.title == "Article 1"
}

pub fn merge_multiple_feeds_test() {
  let feed_a =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Old Article",
            pub_date: some_date("2025-01-01T12:00:00Z"),
          )
        }),
      ])
    })
  let feed_b =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "New Article",
            pub_date: some_date("2025-01-02T12:00:00Z"),
          )
        }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [feed_a, feed_b],
      "Combined",
      "https://example.com",
      100,
      10,
      None,
    )

  assert list.length(result.items) == 2
}

pub fn merge_feeds_limits_test() {
  let items =
    list.range(1, 150)
    |> list.map(fn(n) {
      item(fn(i) { FeedItem(..i, title: "Article " <> string.inspect(n)) })
    })

  let test_feed = feed(fn(f) { Feed(..f, items: items) })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      5,
      10,
      None,
    )

  assert list.length(result.items) == 5
}

pub fn merge_feeds_sorts_by_date_desc_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Old",
            pub_date: some_date("2025-01-01T12:00:00Z"),
          )
        }),
        item(fn(i) {
          FeedItem(
            ..i,
            title: "New",
            pub_date: some_date("2025-01-15T12:00:00Z"),
          )
        }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      None,
    )

  let assert [first, second] = result.items
  assert first.title == "New"
  assert second.title == "Old"
}

// ----------------------------------------------------------------------------
// merge_feeds でのタイトルサニタイズ テスト
// ----------------------------------------------------------------------------

pub fn merge_feeds_strips_html_from_title_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) { FeedItem(..i, title: "<b>Bold Title</b>") }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      None,
    )

  let assert [merged_item] = result.items
  assert merged_item.title == "Bold Title"
}

// ----------------------------------------------------------------------------
// max_age_days テスト
// ----------------------------------------------------------------------------

pub fn merge_feeds_filters_old_items_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Recent",
            pub_date: some_date("2025-01-25T12:00:00Z"),
          )
        }),
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Old",
            pub_date: some_date("2024-12-26T12:00:00Z"),
          )
        }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      some_date("2025-01-15T12:00:00Z"),
    )

  assert list.length(result.items) == 1
  let assert [only_item] = result.items
  assert only_item.title == "Recent"
}

pub fn merge_feeds_keeps_all_when_no_max_age_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Article 1",
            pub_date: some_date("2025-01-01T12:00:00Z"),
          )
        }),
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Article 2",
            pub_date: some_date("2024-01-01T12:00:00Z"),
          )
        }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      None,
    )

  assert list.length(result.items) == 2
}

pub fn merge_feeds_excludes_items_without_date_test() {
  let test_feed =
    feed(fn(f) {
      Feed(..f, items: [
        item(fn(i) {
          FeedItem(
            ..i,
            title: "Recent",
            pub_date: some_date("2025-01-20T12:00:00Z"),
          )
        }),
        item(fn(i) { FeedItem(..i, title: "No Date") }),
      ])
    })

  let result =
    aggregator.merge_feeds(
      [test_feed],
      "Combined",
      "https://example.com",
      100,
      10,
      some_date("2025-01-15T12:00:00Z"),
    )

  assert list.length(result.items) == 1
  let assert [only_item] = result.items
  assert only_item.title == "Recent"
}

// ----------------------------------------------------------------------------
// max_items_per_feed テスト
// ----------------------------------------------------------------------------

pub fn merge_feeds_limits_per_feed_test() {
  let make_items = fn(prefix: String) {
    list.range(1, 6)
    |> list.map(fn(n) {
      item(fn(i) { FeedItem(..i, title: prefix <> string.inspect(n)) })
    })
  }

  let feed1 =
    feed(fn(f) {
      Feed(..f, title: "Feed 1", items: make_items("Feed1 Article "))
    })
  let feed2 =
    feed(fn(f) {
      Feed(..f, title: "Feed 2", items: make_items("Feed2 Article "))
    })

  let result =
    aggregator.merge_feeds(
      [feed1, feed2],
      "Combined",
      "https://example.com",
      100,
      2,
      None,
    )

  assert list.length(result.items) == 4
  let assert [first, second, third, fourth] = result.items
  assert first.title == "Feed1 Article 1"
  assert second.title == "Feed1 Article 2"
  assert third.title == "Feed2 Article 1"
  assert fourth.title == "Feed2 Article 2"
}
