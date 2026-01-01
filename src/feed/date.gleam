// feed/date.gleam - 日付パースヘルパー
//
// RSS/Atomで使用される日付形式のパース

import birl
import gleam/result

/// RFC 2822形式の日付をパース（例: "Wed, 01 Jan 2025 12:00:00 GMT"）
/// RSS 2.0のpubDate要素で使用
pub fn parse_rfc2822(date_str: String) -> Result(birl.Time, Nil) {
  birl.from_http(date_str)
}

/// ISO 8601形式の日付をパース（例: "2025-01-01T12:00:00Z"）
/// Atomのupdated/published要素で使用
pub fn parse_iso8601(date_str: String) -> Result(birl.Time, Nil) {
  birl.parse(date_str)
  |> result.replace_error(Nil)
}
