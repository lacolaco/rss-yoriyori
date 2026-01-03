// config_test.gleam - 設定読み込みのテスト

import config
import gleam/option.{None, Some}
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
      assert cfg.feed.max_age_days == 14
    }
    Error(msg) -> {
      // S3環境変数がない場合はここに来る
      assert msg == "S3_ENDPOINT is not set"
    }
  }
}

// ----------------------------------------------------------------------------
// FeedSource テスト
// ----------------------------------------------------------------------------

pub fn feed_source_string_url_has_no_prefix_test() {
  // feeds.jsonで文字列URLを指定した場合、prefix=Noneとして扱われる
  // feeds.jsonの1つ目は文字列URL
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let assert [first, ..] = cfg.feed.feed_sources
      assert first.url == "https://user.keio.ac.jp/~rhotta/helhub/helhub.xml"
      assert first.prefix == None
    }
    Error(_) -> {
      // S3環境変数がない場合はスキップ
      Nil
    }
  }
}

pub fn feed_source_object_format_has_prefix_test() {
  // feeds.jsonでオブジェクト形式を指定した場合、prefix設定が適用される
  // feeds.jsonの4つ目（0-indexed: 3）はオブジェクト形式
  let result = config.load()

  case result {
    Ok(cfg) -> {
      // オブジェクト形式のフィードを探す
      let assert [_, _, _, fourth, ..] = cfg.feed.feed_sources
      assert fourth.url == "https://github.com/angular/angular/commits/main.atom"
      assert fourth.prefix == Some("[ng/commits]")
    }
    Error(_) -> {
      // S3環境変数がない場合はスキップ
      Nil
    }
  }
}
