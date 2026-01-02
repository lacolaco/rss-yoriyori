// feed_generator_test.gleam - RSS生成のテスト

import birl
import feed/generator
import feed/types.{Feed, FeedItem}
import gleam/list
import gleam/option.{None, Some}
import gleam/string

// ----------------------------------------------------------------------------
// 基本的なRSS生成テスト
// ----------------------------------------------------------------------------

pub fn generate_empty_feed_test() {
  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: Some("A test feed"),
      items: [],
    )

  let xml = generator.to_rss(feed)

  assert string.contains(xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
  assert string.contains(xml, "<rss version=\"2.0\">")
  assert string.contains(xml, "<channel>")
  assert string.contains(xml, "<title>Test Feed</title>")
  assert string.contains(xml, "<link>https://example.com</link>")
  assert string.contains(xml, "<description>A test feed</description>")
  assert string.contains(xml, "</channel>")
  assert string.contains(xml, "</rss>")
}

pub fn generate_feed_with_items_test() {
  let item =
    FeedItem(
      title: "Article 1",
      link: "https://example.com/1",
      description: Some("First article"),
      pub_date: None,
    )

  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: None,
      items: [item],
    )

  let xml = generator.to_rss(feed)

  assert string.contains(xml, "<item>")
  assert string.contains(xml, "<title>Article 1</title>")
  assert string.contains(xml, "<link>https://example.com/1</link>")
  assert string.contains(xml, "<description>First article</description>")
  assert string.contains(xml, "</item>")
}

pub fn generate_feed_with_date_test() {
  let assert Ok(date) = birl.parse("2025-01-01T12:00:00Z")
  let item =
    FeedItem(
      title: "Article with date",
      link: "https://example.com/dated",
      description: None,
      pub_date: Some(date),
    )

  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: None,
      items: [item],
    )

  let xml = generator.to_rss(feed)

  // RFC 2822形式で出力されるはず
  assert string.contains(xml, "<pubDate>")
  assert string.contains(xml, "2025")
}

// ----------------------------------------------------------------------------
// ソートと制限テスト
// ----------------------------------------------------------------------------

pub fn items_sorted_by_date_descending_test() {
  let assert Ok(old_date) = birl.parse("2025-01-01T12:00:00Z")
  let assert Ok(new_date) = birl.parse("2025-01-15T12:00:00Z")

  let old_item =
    FeedItem(
      title: "Old Article",
      link: "https://example.com/old",
      description: None,
      pub_date: Some(old_date),
    )

  let new_item =
    FeedItem(
      title: "New Article",
      link: "https://example.com/new",
      description: None,
      pub_date: Some(new_date),
    )

  // 古い順で渡す
  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: None,
      items: [old_item, new_item],
    )

  let xml = generator.to_rss(feed)

  // <item>で分割して順序を確認
  let parts = string.split(xml, "<item>")
  // parts[0] = header, parts[1] = first item, parts[2] = second item
  let assert [_, first_item, second_item, ..] = parts

  // 新しい記事が先に来るはず
  assert string.contains(first_item, "New Article")
  assert string.contains(second_item, "Old Article")
}

pub fn items_limited_to_100_test() {
  // 150件のアイテムを作成
  let items =
    list.range(1, 150)
    |> list.map(fn(i) {
      FeedItem(
        title: "Article " <> string.inspect(i),
        link: "https://example.com/" <> string.inspect(i),
        description: None,
        pub_date: None,
      )
    })

  let feed =
    Feed(
      title: "Test Feed",
      link: "https://example.com",
      description: None,
      items: items,
    )

  let xml = generator.to_rss(feed)

  // <item>の出現回数をカウント
  let item_count = count_occurrences(xml, "<item>")
  assert item_count == 100
}

// ヘルパー: 文字列内の出現回数をカウント
fn count_occurrences(haystack: String, needle: String) -> Int {
  // needleで分割した結果の長さ - 1 = 出現回数
  string.split(haystack, needle)
  |> list.length
  |> fn(n) { n - 1 }
}
