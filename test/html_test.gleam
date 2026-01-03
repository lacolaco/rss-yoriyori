import feed/html.{strip_tags}

// ----------------------------------------------------------------------------
// strip_html_tags テスト
// ----------------------------------------------------------------------------

pub fn strip_html_tags_plain_text_test() {
  let title = strip_tags("Hello World")
  assert title == "Hello World"
}

pub fn strip_html_tags_simple_tags_test() {
  let title = strip_tags("<span>Hello </span><span>World</span>")
  assert title == "Hello World"
}

pub fn strip_html_tags_nested_tags_test() {
  let title = strip_tags("<span><span>Nested</span></span>")
  assert title == "Nested"
}

pub fn strip_html_tags_complex_test() {
  let input =
    "[khelf] <span class=\"C9DxTc\">2025.12.</span><span>30</span>　"
    <> "<a href=\"https://user.keio.ac.jp/~rhotta/helhub/helhub.xml\">"
    <> "寺澤志帆のホームページ「218. 2つのarmory―armoury...」</a>"
  let expected =
    "[khelf] 2025.12.30　" <> "寺澤志帆のホームページ「218. 2つのarmory―armoury...」"
  let title = strip_tags(input)
  assert title == expected
}
