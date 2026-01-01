// feed_parser_test.gleam - RSS/Atomパーサーのテスト

import feed/parser
import feed/types.{Feed}
import gleam/option.{None, Some}

// ----------------------------------------------------------------------------
// RSS 2.0 パーステスト
// ----------------------------------------------------------------------------

const rss_sample = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<rss version=\"2.0\">
  <channel>
    <title>Example Blog</title>
    <link>https://example.com</link>
    <description>An example RSS feed</description>
    <item>
      <title>First Post</title>
      <link>https://example.com/first</link>
      <description>This is the first post</description>
      <pubDate>Wed, 01 Jan 2025 12:00:00 GMT</pubDate>
    </item>
    <item>
      <title>Second Post</title>
      <link>https://example.com/second</link>
    </item>
  </channel>
</rss>"

pub fn parse_rss_channel_metadata_test() {
  let assert Ok(feed) = parser.parse(rss_sample)

  assert feed.title == "Example Blog"
  assert feed.link == "https://example.com"
  assert feed.description == Some("An example RSS feed")
}

pub fn parse_rss_items_test() {
  let assert Ok(feed) = parser.parse(rss_sample)

  // 2つのアイテムがあるはず
  let assert [first, second] = feed.items

  assert first.title == "First Post"
  assert first.link == "https://example.com/first"
  assert first.description == Some("This is the first post")
  assert first.pub_date != None

  assert second.title == "Second Post"
  assert second.link == "https://example.com/second"
  assert second.description == None
  assert second.pub_date == None
}

// ----------------------------------------------------------------------------
// Atom パーステスト
// ----------------------------------------------------------------------------

const atom_sample = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<feed xmlns=\"http://www.w3.org/2005/Atom\">
  <title>Example Atom Feed</title>
  <link href=\"https://example.com\"/>
  <id>urn:uuid:example-feed</id>
  <updated>2025-01-01T12:00:00Z</updated>
  <entry>
    <title>Atom Entry</title>
    <link href=\"https://example.com/atom-entry\"/>
    <id>urn:uuid:entry-1</id>
    <updated>2025-01-01T10:00:00Z</updated>
    <summary>This is an Atom entry</summary>
  </entry>
</feed>"

pub fn parse_atom_feed_metadata_test() {
  let assert Ok(feed) = parser.parse(atom_sample)

  assert feed.title == "Example Atom Feed"
  assert feed.link == "https://example.com"
}

pub fn parse_atom_entries_test() {
  let assert Ok(feed) = parser.parse(atom_sample)

  let assert [entry] = feed.items

  assert entry.title == "Atom Entry"
  assert entry.link == "https://example.com/atom-entry"
  assert entry.description == Some("This is an Atom entry")
  assert entry.pub_date != None
}

// ----------------------------------------------------------------------------
// エラーケース
// ----------------------------------------------------------------------------

pub fn parse_invalid_xml_returns_error_test() {
  let result = parser.parse("<invalid>")
  assert result != Ok(Feed(title: "", link: "", description: None, items: []))
}

pub fn parse_non_feed_xml_returns_error_test() {
  let result = parser.parse("<html><body>Not a feed</body></html>")
  assert result != Ok(Feed(title: "", link: "", description: None, items: []))
}
