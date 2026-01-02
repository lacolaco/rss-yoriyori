// router.gleam - HTTPリクエストのルーティングを担当

import config.{type Config}
import feed/aggregator
import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

/// HTTPリクエストを受け取り、適切なレスポンスを返す
pub fn handle_request(req: Request, config: Config) -> Response {
  case req.method, wisp.path_segments(req) {
    Get, ["health"] -> health()
    _, ["health"] -> wisp.method_not_allowed([Get])
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

/// POST /aggregate
fn aggregate(config: Config) -> Response {
  case aggregator.run(config) {
    Ok(rss_xml) ->
      wisp.ok()
      |> wisp.set_header("content-type", "application/rss+xml")
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
