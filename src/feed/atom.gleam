// feed/atom.gleam - Atom パーサー

import feed/date
import feed/types.{type Feed, type FeedItem, Feed, FeedItem}
import feed/xml.{type XmlNode, Element}
import gleam/list
import gleam/option.{None}
import gleam/result

/// Atom feedをパース
pub fn parse(children: List(XmlNode)) -> Feed {
  let title = xml.get_text_content(children, "title") |> result.unwrap("")
  let link = get_link(children) |> result.unwrap("")
  let description = None  // Atomにはdescriptionがない

  let items =
    children
    |> list.filter_map(fn(node) {
      case node {
        Element(t, entry_children) if t.name.local == "entry" ->
          Ok(parse_entry(entry_children))
        _ -> Error(Nil)
      }
    })

  Feed(
    title: title,
    link: link,
    description: description,
    items: items,
  )
}

/// Atom entryをパース
fn parse_entry(children: List(XmlNode)) -> FeedItem {
  let title = xml.get_text_content(children, "title") |> result.unwrap("")
  let link = get_link(children) |> result.unwrap("")
  let description =
    xml.get_text_content(children, "summary")
    |> result.or(xml.get_text_content(children, "content"))
    |> option.from_result
  let pub_date =
    xml.get_text_content(children, "updated")
    |> result.or(xml.get_text_content(children, "published"))
    |> result.try(date.parse_iso8601)
    |> option.from_result

  FeedItem(title: title, link: link, description: description, pub_date: pub_date)
}

/// Atomのlink要素からhref属性を取得
fn get_link(children: List(XmlNode)) -> Result(String, Nil) {
  children
  |> list.find_map(fn(node) {
    case node {
      Element(tag, _) if tag.name.local == "link" ->
        xml.get_attribute(tag.attributes, "href")
      _ -> Error(Nil)
    }
  })
}
