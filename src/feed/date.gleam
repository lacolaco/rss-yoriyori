// feed/date.gleam - 日付パース/フォーマット/比較ヘルパー
//
// RSS/Atomで使用される日付形式の変換
// birlライブラリのラッパー

import birl
import gleam/order.{type Order}
import gleam/result

/// RFC 2822形式の日付をパース（例: "Wed, 01 Jan 2025 12:00:00 GMT"）
pub fn parse_rfc2822(date_str: String) -> Result(birl.Time, Nil) {
  birl.from_http(date_str)
}

/// ISO 8601形式の日付をパース（例: "2025-01-01T12:00:00Z"）
pub fn parse_iso8601(date_str: String) -> Result(birl.Time, Nil) {
  birl.parse(date_str)
  |> result.replace_error(Nil)
}

/// RFC 2822形式で日付をフォーマット（例: "Wed, 01 Jan 2025 12:00:00 GMT"）
pub fn format_rfc2822(time: birl.Time) -> String {
  birl.to_http(time)
}

/// 日付を比較（昇順: 古い → 新しい）
pub fn compare(a: birl.Time, b: birl.Time) -> Order {
  birl.compare(a, b)
}

/// 日付を比較（降順: 新しい → 古い）
pub fn compare_desc(a: birl.Time, b: birl.Time) -> Order {
  birl.compare(b, a)
}
