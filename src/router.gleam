// router.gleam - HTTPリクエストのルーティングを担当

import config.{type Config}
import feed/aggregator
import gleam/http.{Get, Post}
import storage/s3
import wisp.{type Request, type Response}

/// HTTPリクエストを受け取り、適切なレスポンスを返す
pub fn handle_request(req: Request, config: Config) -> Response {
  case req.method, wisp.path_segments(req) {
    Get, ["health"] -> health()
    _, ["health"] -> wisp.method_not_allowed([Get])
    Get, ["feed.xml"] -> serve_feed(config)
    _, ["feed.xml"] -> wisp.method_not_allowed([Get])
    Post, ["aggregate"] -> aggregate(config)
    _, ["aggregate"] -> wisp.method_not_allowed([Post])
    _, _ -> wisp.not_found()
  }
}

/// GET /health
fn health() -> Response {
  wisp.ok()
  |> wisp.string_body("OK")
}

/// GET /feed.xml - フィードをストレージから取得して配信
fn serve_feed(config: Config) -> Response {
  case s3.get_object(config.storage, config.feed.output_file) {
    Ok(content) ->
      wisp.ok()
      |> wisp.set_header("content-type", "application/xml; charset=utf-8")
      |> wisp.set_header("cache-control", "public, max-age=300, s-maxage=600")
      |> wisp.string_body(content)
    Error(s3.NotFoundError) -> wisp.not_found()
    Error(_) -> wisp.internal_server_error()
  }
}

/// POST /aggregate
fn aggregate(config: Config) -> Response {
  case aggregator.run(config) {
    Ok(rss_xml) ->
      wisp.ok()
      |> wisp.set_header("content-type", "application/xml; charset=utf-8")
      |> wisp.string_body(rss_xml)
    Error(e) ->
      wisp.internal_server_error()
      |> wisp.string_body(aggregate_error_to_string(e))
  }
}

fn aggregate_error_to_string(e: aggregator.AggregateError) -> String {
  case e {
    aggregator.FetchError(msg) -> "Fetch error: " <> msg
    aggregator.ParseError(msg) -> "Parse error: " <> msg
    aggregator.StorageError(msg) -> "Storage error: " <> msg
  }
}
