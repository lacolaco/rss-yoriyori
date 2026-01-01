// router.gleam - HTTPリクエストのルーティングを担当
//
// Gleam学習ポイント:
// - `import ... as ...`: モジュールに別名をつける
// - `pub fn`: 他のモジュールから呼び出せる公開関数
// - `fn`: モジュール内でのみ使えるプライベート関数
// - `->`: 関数の戻り値の型を示す
// - `case`: パターンマッチング（他言語のswitchに相当するが、より強力）

// gleam/http から HTTP メソッドの型をインポート
// Get, Post などはバリアント（列挙型の値）
import gleam/http.{Get}
import wisp.{type Request, type Response}

// ----------------------------------------------------------------------------
// パブリック関数
// ----------------------------------------------------------------------------

/// HTTPリクエストを受け取り、適切なレスポンスを返す
///
/// Gleam学習ポイント:
/// - `Request` と `Response` は wisp モジュールで定義された型
/// - `///` はドキュメンテーションコメント（gleam docs build で抽出される）
pub fn handle_request(req: Request) -> Response {
  // wisp.path_segments はURLパスを "/" で分割してリストにする
  // 例: "/health" -> ["health"], "/foo/bar" -> ["foo", "bar"]
  //
  // Gleam学習ポイント:
  // - カンマ区切りで複数の値を同時にパターンマッチできる
  // - req.method は gleam/http の Method 型（Get, Post, Put, Delete など）
  case req.method, wisp.path_segments(req) {
    // パターン: GET /health
    Get, ["health"] -> health()

    // パターン: /health に GET 以外のメソッドでアクセス
    // wisp.method_not_allowed は許可メソッドを Allow ヘッダーに含めて 405 を返す
    _, ["health"] -> wisp.method_not_allowed([Get])

    // パターン: それ以外のすべてのパス（_ はワイルドカード）
    _, _ -> wisp.not_found()
  }
}

// ----------------------------------------------------------------------------
// プライベート関数（エンドポイントハンドラー）
// ----------------------------------------------------------------------------

/// GET /health - ヘルスチェックエンドポイント
///
/// Cloud Run はこのエンドポイントを定期的に呼び出して
/// サービスが正常に動作しているか確認する
fn health() -> Response {
  // wisp.ok() は HTTP 200 OK レスポンスを生成
  // wisp.string_body() でレスポンスボディを設定
  wisp.ok()
  |> wisp.string_body("OK")
}
