import gleam/http
import gleam/list
import gleam/string
import gleeunit
import router
import wisp/simulate

pub fn main() -> Nil {
  gleeunit.main()
}

// ----------------------------------------------------------------------------
// GET /health
// ----------------------------------------------------------------------------

pub fn health_returns_ok_test() {
  let request = simulate.request(http.Get, "/health")
  let response = router.handle_request(request)

  assert response.status == 200
  assert simulate.read_body(response) == "OK"
}

pub fn health_rejects_post_test() {
  let request = simulate.request(http.Post, "/health")
  let response = router.handle_request(request)

  assert response.status == 405
}

// ----------------------------------------------------------------------------
// POST /aggregate
// ----------------------------------------------------------------------------

pub fn aggregate_returns_rss_xml_test() {
  let request = simulate.request(http.Post, "/aggregate")
  let response = router.handle_request(request)

  assert response.status == 200

  let body = simulate.read_body(response)
  assert string.starts_with(body, "<?xml")
  assert string.contains(body, "<rss")
}

pub fn aggregate_returns_rss_content_type_test() {
  let request = simulate.request(http.Post, "/aggregate")
  let response = router.handle_request(request)

  let content_type = list.key_find(response.headers, "content-type")
  assert content_type == Ok("application/rss+xml")
}

pub fn aggregate_rejects_get_test() {
  let request = simulate.request(http.Get, "/aggregate")
  let response = router.handle_request(request)

  assert response.status == 405
}

// ----------------------------------------------------------------------------
// 404
// ----------------------------------------------------------------------------

pub fn unknown_path_returns_404_test() {
  let request = simulate.request(http.Get, "/unknown")
  let response = router.handle_request(request)

  assert response.status == 404
}
