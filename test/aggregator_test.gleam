// aggregator_test.gleam - フィード統合ロジックのテスト

import birl
import feed/aggregator
import feed/types.{Feed, FeedItem}
import gleam/list
import gleam/option.{None, Some}
import gleam/string

// ----------------------------------------------------------------------------
// merge_feeds テスト
// ----------------------------------------------------------------------------

pub fn merge_empty_feeds_test() {
  let result =
    aggregator.merge_feeds([], "Combined", "https://example.com", 100, 10)

  assert result.title == "Combined"
  assert result.link == "https://example.com"
  assert result.items == []
}

pub fn merge_single_feed_test() {
  let item =
    FeedItem(
      title: "Article 1",
      link: "https://a.com/1",
      description: Some("Description"),
      pub_date: None,
    )

  let feed =
    Feed(
      title: "Feed A",
      link: "https://a.com",
      description: Some("Feed A desc"),
      items: [item],
    )

  let result =
    aggregator.merge_feeds([feed], "Combined", "https://example.com", 100, 10)

  assert result.title == "Combined"
  assert list.length(result.items) == 1
  let assert [merged_item] = result.items
  assert merged_item.title == "Article 1"
}

pub fn merge_multiple_feeds_test() {
  let assert Ok(date1) = birl.parse("2025-01-01T12:00:00Z")
  let assert Ok(date2) = birl.parse("2025-01-02T12:00:00Z")

  let item_a =
    FeedItem(
      title: "Old Article",
      link: "https://a.com/old",
      description: None,
      pub_date: Some(date1),
    )

  let item_b =
    FeedItem(
      title: "New Article",
      link: "https://b.com/new",
      description: None,
      pub_date: Some(date2),
    )

  let feed_a =
    Feed(title: "Feed A", link: "https://a.com", description: None, items: [
      item_a,
    ])

  let feed_b =
    Feed(title: "Feed B", link: "https://b.com", description: None, items: [
      item_b,
    ])

  let result =
    aggregator.merge_feeds(
      [feed_a, feed_b],
      "Combined",
      "https://example.com",
      100,
      10,
    )

  assert list.length(result.items) == 2
}

pub fn merge_feeds_limits_test() {
  // 150件のアイテムを持つフィードを作成
  let items =
    list.range(1, 150)
    |> list.map(fn(i) {
      FeedItem(
        title: "Article " <> string.inspect(i),
        link: "https://a.com/" <> string.inspect(i),
        description: None,
        pub_date: None,
      )
    })

  let feed =
    Feed(
      title: "Big Feed",
      link: "https://a.com",
      description: None,
      items: items,
    )

  let result =
    aggregator.merge_feeds([feed], "Combined", "https://example.com", 5, 10)

  assert list.length(result.items) == 5
}

pub fn merge_feeds_sorts_by_date_desc_test() {
  let assert Ok(old_date) = birl.parse("2025-01-01T12:00:00Z")
  let assert Ok(new_date) = birl.parse("2025-01-15T12:00:00Z")

  let old_item =
    FeedItem(
      title: "Old",
      link: "https://a.com/old",
      description: None,
      pub_date: Some(old_date),
    )

  let new_item =
    FeedItem(
      title: "New",
      link: "https://b.com/new",
      description: None,
      pub_date: Some(new_date),
    )

  // 古い順で渡す
  let feed =
    Feed(title: "Feed", link: "https://a.com", description: None, items: [
      old_item,
      new_item,
    ])

  let result =
    aggregator.merge_feeds([feed], "Combined", "https://example.com", 100, 10)

  let assert [first, second] = result.items
  // 新しい記事が先に来るはず
  assert first.title == "New"
  assert second.title == "Old"
}

// ----------------------------------------------------------------------------
// max_items_per_feed テスト
// ----------------------------------------------------------------------------

pub fn merge_feeds_limits_per_feed_test() {
  // TODO(human): 各フィードから最大N件取得することを検証するテストを書く
  // - 2つのフィードを作成（各5件のアイテム）
  // - max_items_per_feed=2 で merge_feeds を呼ぶ
  // - 結果が4件（2件 x 2フィード）であることを検証
  let feed1 =
    Feed(
      title: "Feed 1",
      link: "https://feed1.com",
      description: None,
      items: list.range(1, 6)
        |> list.map(fn(i) {
          FeedItem(
            title: "Feed1 Article " <> string.inspect(i),
            link: "https://feed1.com/" <> string.inspect(i),
            description: None,
            pub_date: None,
          )
        }),
    )
  let feed2 =
    Feed(
      title: "Feed 2",
      link: "https://feed2.com",
      description: None,
      items: list.range(1, 6)
        |> list.map(fn(i) {
          FeedItem(
            title: "Feed2 Article " <> string.inspect(i),
            link: "https://feed2.com/" <> string.inspect(i),
            description: None,
            pub_date: None,
          )
        }),
    )
  let result =
    aggregator.merge_feeds(
      [feed1, feed2],
      "Combined",
      "https://example.com",
      100,
      2,
    )

  assert list.length(result.items) == 4
  let assert [first, second, third, fourth] = result.items
  assert first.title == "Feed1 Article 1"
  assert second.title == "Feed1 Article 2"
  assert third.title == "Feed2 Article 1"
  assert fourth.title == "Feed2 Article 2"
  Nil
}
