// feed/generator.gleam - RSS 2.0 フィード生成
//
// FeedをRSS 2.0形式のXMLに変換

import feed/date
import feed/types.{type Feed, type FeedItem}
import feed/xml
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/string

/// 最大アイテム数
const max_items = 100

/// FeedをRSS 2.0形式のXML文字列に変換
/// - アイテムは日付降順でソート
/// - 最大100件に制限
pub fn to_rss(feed: Feed) -> String {
  let items =
    feed.items
    |> sort_by_date_desc
    |> list.take(max_items)

  let items_xml =
    items
    |> list.map(item_to_xml)
    |> string.join("")

  let description_xml = case feed.description {
    Some(desc) -> "<description>" <> xml.escape(desc) <> "</description>"
    None -> "<description></description>"
  }

  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  <> "<rss version=\"2.0\">"
  <> "<channel>"
  <> "<title>"
  <> xml.escape(feed.title)
  <> "</title>"
  <> "<link>"
  <> xml.escape(feed.link)
  <> "</link>"
  <> description_xml
  <> items_xml
  <> "</channel>"
  <> "</rss>"
}

/// アイテムを日付降順でソート（新しいものが先）
fn sort_by_date_desc(items: List(FeedItem)) -> List(FeedItem) {
  list.sort(items, fn(a, b) {
    case a.pub_date, b.pub_date {
      Some(date_a), Some(date_b) -> date.compare_desc(date_a, date_b)
      Some(_), None -> order.Lt
      None, Some(_) -> order.Gt
      None, None -> order.Eq
    }
  })
}

/// FeedItemをXMLに変換
fn item_to_xml(item: FeedItem) -> String {
  let description_xml = case item.description {
    Some(desc) -> "<description>" <> xml.escape(desc) <> "</description>"
    None -> ""
  }

  let pub_date_xml = case item.pub_date {
    Some(d) -> "<pubDate>" <> date.format_rfc2822(d) <> "</pubDate>"
    None -> ""
  }

  "<item>"
  <> "<title>"
  <> xml.escape(item.title)
  <> "</title>"
  <> "<link>"
  <> xml.escape(item.link)
  <> "</link>"
  <> description_xml
  <> pub_date_xml
  <> "</item>"
}
