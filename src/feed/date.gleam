// feed/date.gleam - 日付パース/フォーマット/比較ヘルパー
//
// RSS/Atomで使用される日付形式の変換
// birlライブラリのラッパー

import birl
import birl/duration
import gleam/option
import gleam/order.{type Order}
import gleam/result

/// Time型をre-export
pub type Time =
  birl.Time

/// RFC 2822形式の日付をパース（例: "Wed, 01 Jan 2025 12:00:00 GMT"）
pub fn parse_rfc2822(date_str: String) -> Result(Time, Nil) {
  birl.from_http(date_str)
}

/// ISO 8601形式の日付をパース（例: "2025-01-01T12:00:00Z"）
pub fn parse_iso8601(date_str: String) -> Result(Time, Nil) {
  birl.parse(date_str)
  |> result.replace_error(Nil)
}

/// RFC 2822形式で日付をフォーマット（例: "Wed, 01 Jan 2025 12:00:00 GMT"）
pub fn format_rfc2822(time: Time) -> String {
  birl.to_http(time)
}

/// 日付を比較（昇順: 古い → 新しい）
pub fn compare(a: Time, b: Time) -> Order {
  birl.compare(a, b)
}

/// 日付を比較（降順: 新しい → 古い）
pub fn compare_desc(a: Time, b: Time) -> Order {
  birl.compare(b, a)
}

/// aがbより後の日付かどうかを判定
pub fn is_after(a: Time, b: Time) -> Bool {
  birl.compare(a, b) == order.Gt
}

/// 現在時刻を取得
pub fn now() -> Time {
  birl.now()
}

/// 指定日数前の時刻を計算
pub fn subtract_days(time: Time, days: Int) -> Time {
  birl.subtract(time, duration.days(days))
}

/// max_age_days から threshold_date を計算
/// 0以下の場合は None を返す（制限なし）
pub fn threshold_from_max_age_days(max_age_days: Int) -> option.Option(Time) {
  case max_age_days > 0 {
    True -> option.Some(subtract_days(now(), max_age_days))
    False -> option.None
  }
}
