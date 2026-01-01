// feed/xml.gleam - XML木構造のヘルパー関数
//
// xmlmでパースした木構造を操作するユーティリティ

import gleam/list
import gleam/option.{type Option}
import gleam/string
import xmlm.{type Tag, Attribute}

/// 内部用XML木構造
pub type XmlNode {
  Element(tag: Tag, children: List(XmlNode))
  Text(String)
}

/// 子要素から指定名の要素を探す
pub fn find_element(children: List(XmlNode), name: String) -> Option(XmlNode) {
  children
  |> list.find(fn(node) {
    case node {
      Element(tag, _) -> tag.name.local == name
      Text(_) -> False
    }
  })
  |> option.from_result
}

/// 指定名の要素のテキスト内容を取得
pub fn get_text_content(children: List(XmlNode), name: String) -> Result(String, Nil) {
  case find_element(children, name) {
    option.Some(Element(_, element_children)) -> {
      let text =
        element_children
        |> list.filter_map(fn(node) {
          case node {
            Text(t) -> Ok(t)
            _ -> Error(Nil)
          }
        })
        |> string.concat
        |> string.trim

      case text {
        "" -> Error(Nil)
        t -> Ok(t)
      }
    }
    _ -> Error(Nil)
  }
}

/// 属性リストから指定名の属性値を取得
pub fn get_attribute(attrs: List(xmlm.Attribute), name: String) -> Result(String, Nil) {
  attrs
  |> list.find_map(fn(attr) {
    case attr {
      Attribute(attr_name, value) if attr_name.local == name -> Ok(value)
      _ -> Error(Nil)
    }
  })
}

/// XML特殊文字をエスケープ
pub fn escape(s: String) -> String {
  s
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&apos;")
}
