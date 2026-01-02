// feed/rss.gleam - RSS 2.0 パーサー

import feed/date
import feed/types.{type Feed, type FeedItem, Feed, FeedItem}
import feed/xml.{type XmlNode, Element, Text}
import gleam/list
import gleam/option
import gleam/result

/// パースエラー
pub type RssError {
  ChannelNotFound
}

/// RSS 2.0のchannelをパース
pub fn parse(rss_children: List(XmlNode)) -> Result(Feed, RssError) {
  case xml.find_element(rss_children, "channel") {
    option.None -> Error(ChannelNotFound)
    option.Some(Element(_, channel_children)) -> {
      let title =
        xml.get_text_content(channel_children, "title") |> result.unwrap("")
      let link =
        xml.get_text_content(channel_children, "link") |> result.unwrap("")
      let description =
        xml.get_text_content(channel_children, "description")
        |> option.from_result

      let items =
        channel_children
        |> list.filter_map(fn(node) {
          case node {
            Element(tag, children) if tag.name.local == "item" ->
              Ok(parse_item(children))
            _ -> Error(Nil)
          }
        })

      Ok(Feed(title: title, link: link, description: description, items: items))
    }
    option.Some(Text(_)) -> Error(ChannelNotFound)
  }
}

/// RSS itemをパース
fn parse_item(children: List(XmlNode)) -> FeedItem {
  let title = xml.get_text_content(children, "title") |> result.unwrap("")
  let link = xml.get_text_content(children, "link") |> result.unwrap("")
  let description =
    xml.get_text_content(children, "description") |> option.from_result
  let pub_date =
    xml.get_text_content(children, "pubDate")
    |> result.try(date.parse_rfc2822)
    |> option.from_result

  FeedItem(
    title: title,
    link: link,
    description: description,
    pub_date: pub_date,
  )
}
