// rss_yoriyori.gleam - アプリケーションのエントリーポイント
//
// Gleam学習ポイント:
// - `import`: 他のモジュールを読み込む
// - `let`: 変数束縛（イミュータブル、再代入不可）
// - `|>`: パイプ演算子（前の式の結果を次の関数の第一引数に渡す）
// - `Result`: 成功(Ok)または失敗(Error)を表す型

import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import mist
import router
import wisp
import wisp/wisp_mist

// ----------------------------------------------------------------------------
// 定数
// ----------------------------------------------------------------------------

/// デフォルトのポート番号
/// Cloud Run は PORT 環境変数でポートを指定する
/// ローカル開発時はこのデフォルト値を使用
const default_port = 8080

// ----------------------------------------------------------------------------
// メイン関数
// ----------------------------------------------------------------------------

/// アプリケーションのエントリーポイント
///
/// Gleam学習ポイント:
/// - `Nil` は「何も返さない」を表す型（他言語の void に相当）
/// - Gleam では最後の式が自動的に戻り値になる（return キーワード不要）
pub fn main() -> Nil {
  // ログ出力の設定
  // wisp はログを構造化して出力できる
  wisp.configure_logger()

  // 環境変数 PORT を読み取る
  // envoy.get は Result(String, Nil) を返す
  // result.try は Ok の場合のみ次の関数を適用し、Error はそのまま伝播
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(default_port)

  // wisp用のシークレットキー生成（セッション等に使用）
  let secret_key_base = wisp.random_string(64)

  // リクエストハンドラーを作成
  // fn(req) { ... } は無名関数（ラムダ式）
  let handler = fn(req) { router.handle_request(req) }

  // HTTPサーバーを起動
  // |> はパイプ演算子：左の結果を右の関数の第一引数に渡す
  // mist.bind("0.0.0.0") で全インターフェースでリッスン（Docker対応）
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  // 起動メッセージを出力
  io.println("Server started on port " <> int.to_string(port))

  // サーバーを永続的に実行し続ける
  // Erlang プロセスを sleep させることで、main が終了しないようにする
  process.sleep_forever()
}
