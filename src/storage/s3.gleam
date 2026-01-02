// storage/s3.gleam - S3互換ストレージクライアント
//
// MinIO（ローカル）とGCS（本番、S3互換API）の両方に対応
// 依存性注入: 環境変数でエンドポイントを切り替え
//
// 環境変数:
// - S3_ENDPOINT: エンドポイント（必須）
// - S3_ACCESS_KEY: アクセスキー（必須）
// - S3_SECRET_KEY: シークレットキー（必須）
// - S3_BUCKET: バケット名（必須）
// - S3_USE_SSL: SSL使用有無（"true"/"false"、デフォルト: false）

import bucket
import bucket/put_object
import envoy
import gleam/bit_array
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/result
import gleam/string

/// ストレージ設定
/// 環境変数から構築し、MinIO/GCSを切り替える
pub type StorageConfig {
  StorageConfig(
    endpoint: String,
    access_key: String,
    secret_key: String,
    bucket_name: String,
    use_ssl: Bool,
  )
}

/// ストレージ操作の結果
pub type StorageError {
  ConnectionError(String)
  UploadError(String)
}

/// 環境変数から設定を読み込む
/// すべての環境変数が設定されていない場合はエラーを返す
pub fn config_from_env() -> Result(StorageConfig, String) {
  use endpoint <- result.try(
    envoy.get("S3_ENDPOINT")
    |> result.replace_error("S3_ENDPOINT is not set"),
  )
  use access_key <- result.try(
    envoy.get("S3_ACCESS_KEY")
    |> result.replace_error("S3_ACCESS_KEY is not set"),
  )
  use secret_key <- result.try(
    envoy.get("S3_SECRET_KEY")
    |> result.replace_error("S3_SECRET_KEY is not set"),
  )
  use bucket_name <- result.try(
    envoy.get("S3_BUCKET")
    |> result.replace_error("S3_BUCKET is not set"),
  )

  let use_ssl =
    envoy.get("S3_USE_SSL")
    |> result.map(fn(val) { string.lowercase(val) == "true" })
    |> result.unwrap(False)

  Ok(StorageConfig(
    endpoint: endpoint,
    access_key: access_key,
    secret_key: secret_key,
    bucket_name: bucket_name,
    use_ssl: use_ssl,
  ))
}

/// ファイルをアップロード
pub fn put_object(
  config: StorageConfig,
  key: String,
  body: String,
  content_type: String,
) -> Result(Nil, StorageError) {
  // bucket パッケージの credentials を作成
  let creds =
    bucket.credentials(config.endpoint, config.access_key, config.secret_key)
    |> bucket.with_scheme(case config.use_ssl {
      True -> http.Https
      False -> http.Http
    })

  // 文字列をBitArrayに変換
  let body_bits = bit_array.from_string(body)

  // リクエストを構築
  let req =
    put_object.request(bucket: config.bucket_name, key: key, body: body_bits)
    |> put_object.build(creds)

  // Content-Type ヘッダーを追加
  let req = request.set_header(req, "content-type", content_type)

  // HTTPリクエストを送信
  case httpc.send_bits(req) {
    Ok(response) ->
      case response.status {
        200 -> Ok(Nil)
        status ->
          Error(UploadError(
            "Upload failed with status: " <> int.to_string(status),
          ))
      }
    Error(_) -> Error(ConnectionError("Failed to connect to storage"))
  }
}
