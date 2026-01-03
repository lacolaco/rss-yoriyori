// feed/html.gleam - HTML処理ユーティリティ

import gleam/string

/// HTMLタグを除去してプレーンテキストに変換
/// タグ内の属性やコンテンツは除去され、テキストノードのみが残る
pub fn strip_tags(html: String) -> String {
  strip_tags_loop(html, "", False)
}

fn strip_tags_loop(input: String, acc: String, in_tag: Bool) -> String {
  case string.pop_grapheme(input) {
    Error(_) -> acc
    Ok(#("<", rest)) -> strip_tags_loop(rest, acc, True)
    Ok(#(">", rest)) -> strip_tags_loop(rest, acc, False)
    Ok(#(_, rest)) if in_tag -> strip_tags_loop(rest, acc, True)
    Ok(#(char, rest)) -> strip_tags_loop(rest, acc <> char, False)
  }
}
