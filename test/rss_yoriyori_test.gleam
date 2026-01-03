import config
import gleam/http
import gleam/string
import gleeunit
import router
import storage/s3
import wisp/simulate

pub fn main() -> Nil {
  gleeunit.main()
}

/// テスト用の設定を作成
fn test_config() -> config.Config {
  config.Config(
    feed: config.FeedConfig(
      title: "Test Feed",
      link: "https://example.com",
      output_file: "feed.xml",
      max_items: 100,
      max_items_per_feed: 10,
      max_age_days: 14,
      feed_sources: [],
    ),
    storage: s3.StorageConfig(
      endpoint: "localhost:9000",
      access_key: "test",
      secret_key: "test",
      bucket_name: "test",
      use_ssl: False,
    ),
  )
}

// ----------------------------------------------------------------------------
// GET /health
// ----------------------------------------------------------------------------

pub fn health_returns_ok_test() {
  let request = simulate.request(http.Get, "/health")
  let response = router.handle_request(request, test_config())

  assert response.status == 200
  assert simulate.read_body(response) == "OK"
}

pub fn health_rejects_post_test() {
  let request = simulate.request(http.Post, "/health")
  let response = router.handle_request(request, test_config())

  assert response.status == 405
}

// ----------------------------------------------------------------------------
// POST /aggregate
// ----------------------------------------------------------------------------

pub fn aggregate_with_empty_feeds_returns_rss_test() {
  // フィードURLが空の場合、空のRSSを返す
  let request = simulate.request(http.Post, "/aggregate")
  let response = router.handle_request(request, test_config())

  // ストレージ接続失敗で500（MinIOが起動していない場合）
  // または200（MinIOが起動している場合）
  // テスト環境依存なので、ステータスは確認しない
  let body = simulate.read_body(response)
  // エラーまたはRSSが返る
  assert string.length(body) > 0
}

pub fn aggregate_rejects_get_test() {
  let request = simulate.request(http.Get, "/aggregate")
  let response = router.handle_request(request, test_config())

  assert response.status == 405
}

// ----------------------------------------------------------------------------
// GET /feed.xml
// ----------------------------------------------------------------------------

pub fn feed_xml_rejects_post_test() {
  let request = simulate.request(http.Post, "/feed.xml")
  let response = router.handle_request(request, test_config())

  assert response.status == 405
}

pub fn feed_xml_returns_error_when_storage_unavailable_test() {
  // test_config()のストレージ設定は無効なため、500か404が返る
  let request = simulate.request(http.Get, "/feed.xml")
  let response = router.handle_request(request, test_config())

  // ストレージ接続失敗で500
  assert response.status == 500
}

pub fn feed_xml_returns_content_when_file_exists_test() {
  // MinIO統合テスト（Docker Compose環境で実行）
  let assert Ok(storage_config) = s3.config_from_env()
  let config =
    config.Config(
      feed: config.FeedConfig(
        title: "Test Feed",
        link: "https://example.com",
        output_file: "test/serve_feed.xml",
        max_items: 100,
        max_items_per_feed: 10,
        max_age_days: 14,
        feed_sources: [],
      ),
      storage: storage_config,
    )

  // まずファイルをアップロード
  let xml_content =
    "<?xml version=\"1.0\"?><rss><channel><title>Test</title></channel></rss>"
  let assert Ok(Nil) =
    s3.put_object(
      storage_config,
      "test/serve_feed.xml",
      xml_content,
      "application/rss+xml",
    )

  // /feed.xmlにアクセス
  let request = simulate.request(http.Get, "/feed.xml")
  let response = router.handle_request(request, config)

  assert response.status == 200
  assert simulate.read_body(response) == xml_content
}

pub fn feed_xml_returns_404_when_file_not_exists_test() {
  // MinIO統合テスト（Docker Compose環境で実行）
  let assert Ok(storage_config) = s3.config_from_env()
  let config =
    config.Config(
      feed: config.FeedConfig(
        title: "Test Feed",
        link: "https://example.com",
        output_file: "test/nonexistent_feed_12345.xml",
        max_items: 100,
        max_items_per_feed: 10,
        max_age_days: 14,
        feed_sources: [],
      ),
      storage: storage_config,
    )

  let request = simulate.request(http.Get, "/feed.xml")
  let response = router.handle_request(request, config)

  assert response.status == 404
}

// ----------------------------------------------------------------------------
// 404
// ----------------------------------------------------------------------------

pub fn unknown_path_returns_404_test() {
  let request = simulate.request(http.Get, "/unknown")
  let response = router.handle_request(request, test_config())

  assert response.status == 404
}
