// rss_yoriyori.gleam - アプリケーションのエントリーポイント

import config
import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import mist
import router
import wisp
import wisp/wisp_mist

const default_port = 8080

/// アプリケーションのエントリーポイント
pub fn main() -> Nil {
  wisp.configure_logger()

  // 起動時に設定を読み込み（フェイルファスト）
  let assert Ok(app_config) = config.load()

  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(default_port)

  let secret_key_base = wisp.random_string(64)

  // クロージャで設定をキャプチャ
  let handler = fn(req) { router.handle_request(req, app_config) }

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  io.println("Server started on port " <> int.to_string(port))

  process.sleep_forever()
}
