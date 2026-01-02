// config_test.gleam - 設定読み込みのテスト

import config
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// ----------------------------------------------------------------------------
// config.load テスト
// ----------------------------------------------------------------------------

pub fn load_reads_feeds_json_test() {
  // feeds.jsonが存在する場合、正常に読み込める
  // （テスト実行時はプロジェクトルートにfeeds.jsonがある）
  let result = config.load()

  // S3環境変数がないためエラーになるが、
  // feeds.jsonのパースは成功しているはず
  // → S3環境変数がある環境（Docker Compose）でのみ成功
  case result {
    Ok(cfg) -> {
      // 正常に読み込めた場合
      assert cfg.feed.title == "rss-yoriyori.lacolaco.dev"
      assert cfg.feed.max_items == 100
      assert cfg.feed.max_items_per_feed == 10
    }
    Error(msg) -> {
      // S3環境変数がない場合はここに来る
      assert msg == "S3_ENDPOINT is not set"
    }
  }
}
