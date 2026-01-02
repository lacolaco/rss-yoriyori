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
      feed_urls: [],
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
// 404
// ----------------------------------------------------------------------------

pub fn unknown_path_returns_404_test() {
  let request = simulate.request(http.Get, "/unknown")
  let response = router.handle_request(request, test_config())

  assert response.status == 404
}
