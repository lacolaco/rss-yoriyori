// feed/aggregator.gleam - フィード統合ロジック
//
// 複数のフィードを1つに統合し、ストレージにアップロード

import config.{type Config}
import feed/date.{type Time}
import feed/generator
import feed/html
import feed/parser
import feed/types.{type Feed, type FeedItem, Feed, FeedItem}
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import storage/s3

/// 集約エラー
pub type AggregateError {
  FetchError(String)
  ParseError(String)
  StorageError(String)
}

/// 集約処理を実行
pub fn run(config: Config) -> Result(String, AggregateError) {
  let feed_config = config.feed

  // 各URLからフィードを取得・パース
  let feeds =
    feed_config.feed_urls
    |> list.filter_map(fn(url) {
      fetch_and_parse(url)
      |> result.replace_error(Nil)
    })

  // threshold_date を計算
  let threshold_date =
    date.threshold_from_max_age_days(feed_config.max_age_days)

  // フィードを統合
  let merged =
    merge_feeds(
      feeds,
      feed_config.title,
      feed_config.link,
      feed_config.max_items,
      feed_config.max_items_per_feed,
      threshold_date,
    )

  // RSS XMLを生成
  let rss_xml = generator.to_rss(merged)

  // ストレージにアップロード
  use _ <- result.try(upload_to_storage(
    config.storage,
    feed_config.output_file,
    rss_xml,
  ))

  Ok(rss_xml)
}

/// URLからフィードを取得してパース
fn fetch_and_parse(url: String) -> Result(Feed, AggregateError) {
  use body <- result.try(fetch_url(url))
  case parser.parse(body) {
    Ok(feed) -> Ok(feed)
    Error(e) ->
      Error(ParseError(
        "Failed to parse " <> url <> ": " <> parse_error_to_string(e),
      ))
  }
}

/// URLからコンテンツを取得
fn fetch_url(url: String) -> Result(String, AggregateError) {
  case request.to(url) {
    Error(_) -> Error(FetchError("Invalid URL: " <> url))
    Ok(req) -> {
      case httpc.send(req) {
        Ok(response) ->
          case response.status {
            200 -> Ok(response.body)
            status ->
              Error(FetchError("HTTP " <> string.inspect(status) <> ": " <> url))
          }
        Error(_) -> Error(FetchError("Connection failed: " <> url))
      }
    }
  }
}

/// ストレージにアップロード
fn upload_to_storage(
  storage_config: s3.StorageConfig,
  output_file: String,
  content: String,
) -> Result(Nil, AggregateError) {
  case
    s3.put_object(storage_config, output_file, content, "application/rss+xml")
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(StorageError(storage_error_to_string(e)))
  }
}

/// ParseErrorを文字列に変換
fn parse_error_to_string(e: parser.ParseError) -> String {
  case e {
    parser.InvalidXml(msg) -> "Invalid XML: " <> msg
    parser.UnsupportedFormat(msg) -> "Unsupported format: " <> msg
  }
}

/// StorageErrorを文字列に変換
fn storage_error_to_string(e: s3.StorageError) -> String {
  case e {
    s3.ConnectionError(msg) -> "Connection error: " <> msg
    s3.UploadError(msg) -> "Upload error: " <> msg
    s3.NotFoundError -> "Object not found"
  }
}

/// 複数のフィードを1つに統合
/// - 全フィードのアイテムを結合
/// - 日付降順でソート
/// - max_items件に制限
pub fn merge_feeds(
  feeds: List(Feed),
  title: String,
  link: String,
  max_items: Int,
  max_items_per_feed: Int,
  threshold_date: option.Option(Time),
) -> Feed {
  let items =
    feeds
    |> list.flat_map(fn(feed) {
      feed.items
      // threshold_date が指定されていれば古いアイテムを除外
      // pub_date が None のアイテムも除外
      |> list.filter(fn(item) {
        case threshold_date {
          Some(threshold) ->
            case item.pub_date {
              Some(pub_date) -> date.is_after(pub_date, threshold)
              None -> False
            }
          None -> True
        }
      })
      |> list.take(max_items_per_feed)
    })
    |> sort_by_date_desc
    |> list.take(max_items)
    |> list.map(fn(item) {
      // タイトルからHTMLタグを除去
      FeedItem(..item, title: html.strip_tags(item.title))
    })

  Feed(title: title, link: link, description: None, items: items)
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
