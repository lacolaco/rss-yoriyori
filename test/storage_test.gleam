// storage_test.gleam - S3互換ストレージのテスト
//
// 環境変数から設定を読み込み、MinIOに対してテスト実行
// compose環境で実行: make test

import gleam/result
import storage/s3

// ----------------------------------------------------------------------------
// config_from_env テスト
// ----------------------------------------------------------------------------

pub fn config_from_env_reads_environment_variables_test() {
  let result = s3.config_from_env()
  assert result.is_ok(result) == True
}

pub fn config_from_env_returns_correct_values_test() {
  let assert Ok(config) = s3.config_from_env()

  // compose.yamlで設定された値と一致することを確認
  assert config.endpoint == "minio:9000"
  assert config.access_key == "minioadmin"
  assert config.secret_key == "minioadmin"
  assert config.bucket_name == "rss-yoriyori"
  assert config.use_ssl == False
}

// ----------------------------------------------------------------------------
// put_object テスト（統合テスト - MinIO必須）
// ----------------------------------------------------------------------------

pub fn put_object_uploads_to_minio_test() {
  let assert Ok(config) = s3.config_from_env()

  let result =
    s3.put_object(config, "test/hello.txt", "Hello, MinIO!", "text/plain")

  assert result == Ok(Nil)
}

pub fn put_object_uploads_xml_test() {
  let assert Ok(config) = s3.config_from_env()

  let xml = "<?xml version=\"1.0\"?><rss><channel></channel></rss>"
  let result = s3.put_object(config, "test/feed.xml", xml, "application/rss+xml")

  assert result == Ok(Nil)
}
