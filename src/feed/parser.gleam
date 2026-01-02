// feed/parser.gleam - フィードパーサーのエントリーポイント
//
// RSS 2.0 と Atom を自動判定してパース

import feed/atom
import feed/rss
import feed/types.{type Feed}
import feed/xml.{Element, Text}
import xmlm

/// パースエラー
pub type ParseError {
  InvalidXml(String)
  UnsupportedFormat(String)
}

/// XML文字列をパースしてFeedを返す
/// RSS 2.0 と Atom 両方をサポート
pub fn parse(xml_str: String) -> Result(Feed, ParseError) {
  let input = xmlm.from_string(xml_str)

  // XMLを木構造にパース
  case xmlm.document_tree(input, Element, Text) {
    Error(e) -> Error(InvalidXml(xmlm.input_error_to_string(e)))
    Ok(#(_, tree, _)) -> parse_tree(tree)
  }
}

/// 木構造からフィード形式を判定してパース
fn parse_tree(tree: xml.XmlNode) -> Result(Feed, ParseError) {
  case tree {
    Text(_) -> Error(UnsupportedFormat("Root element expected"))
    Element(tag, children) -> {
      case tag.name.local {
        "rss" ->
          rss.parse(children)
          |> map_rss_error
        "feed" -> Ok(atom.parse(children))
        _ -> Error(UnsupportedFormat("Unknown format: " <> tag.name.local))
      }
    }
  }
}

/// RSSエラーをParseErrorに変換
fn map_rss_error(result: Result(Feed, rss.RssError)) -> Result(Feed, ParseError) {
  case result {
    Ok(feed) -> Ok(feed)
    Error(rss.ChannelNotFound) -> Error(InvalidXml("channel element not found"))
  }
}
