# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rss_yoriyori is a Gleam library/application. Gleam is a type-safe functional programming language that compiles to Erlang and JavaScript.

## Build Commands

```sh
gleam build      # Compile the project
gleam run        # Run the project
gleam test       # Run all tests
gleam docs build # Generate documentation
```

## Testing

Tests are located in `test/` and use the gleeunit testing framework. Test functions must end with `_test` suffix to be discovered and run.

## Project Structure

- `src/` - Source files (`.gleam`)
- `test/` - Test files (`.gleam`)
- `gleam.toml` - Project configuration and dependencies
- `manifest.toml` - Locked dependency versions (auto-generated)

## Gleam Language Notes

- Gleam uses `assert` for assertions in tests
- String concatenation uses `<>`
- All functions must have explicit return types
- Pattern matching is the primary control flow mechanism

### 命名規則

| 対象 | スタイル | 例 |
|------|----------|-----|
| 変数・関数 | `snake_case` | `default_port`, `handle_request` |
| 型 | `PascalCase` | `Result`, `FeedItem` |
| モジュール | `snake_case` | `gleam/int`, `router` |

### let vs const

- `const`: モジュールトップレベル、コンパイル時定数（リテラルのみ）
- `let`: 関数内、実行時束縛（再代入不可、イミュータブル）

### パイプ演算子 `|>`

左辺の結果を右辺の関数の**第1引数**に渡す：

```gleam
// これは
wisp.ok()
|> wisp.set_header("content-type", "application/rss+xml")
|> wisp.string_body(rss_xml)

// これと同じ
wisp.string_body(
  wisp.set_header(wisp.ok(), "content-type", "application/rss+xml"),
  rss_xml
)
```

制約：
- 右辺は必ず関数呼び出し（括弧必須）: `|> func()` ○ / `|> func` ✗
- 第1引数の型が一致しないとコンパイルエラー
- 引数0個の関数にはパイプできない

### Result型のチェーン

```gleam
envoy.get("PORT")           // Result(String, Nil)
|> result.try(int.parse)    // Ok → 変換、Error → 伝播
|> result.unwrap(8080)      // デフォルト値で取り出し
```

- `result.try`: Okの場合のみ次の関数を適用（旧名: `result.then`は非推奨）
- `result.unwrap`: デフォルト値付きで値を取り出す

### テストのコロケーション

- gleeunitは`test/`ディレクトリのみ検索（ハードコード）
- `src/`内のテストを使いたい場合は`test/`から再エクスポート、またはGlacierを使用

### wispハンドラーのテスト

`wisp/simulate`モジュールを使用：

```gleam
import gleam/http
import wisp/simulate
import router

pub fn my_endpoint_test() {
  // リクエスト作成
  let request = simulate.request(http.Post, "/path")

  // ハンドラー呼び出し
  let response = router.handle_request(request)

  // アサーション
  assert response.status == 200
  let body = simulate.read_body(response)
  assert string.contains(body, "expected")
}
```

- `simulate.request(method, path)`: テスト用リクエスト生成
- `simulate.read_body(response)`: レスポンスボディを文字列で取得
- `simulate.string_body(content)`: リクエストにボディを設定

## Docker

- mist HTTPサーバーはデフォルトで`127.0.0.1`にバインド
- Docker対応には`mist.bind("0.0.0.0")`が必要
- ビルダーとランタイムのErlangバージョンを一致させること

## 開発ワークフロー

### ローカル開発

```sh
make up    # ビルド＆起動（Docker Compose）
make down  # 停止
make logs  # ログ表示
```

### 本番デプロイ

GitHub Actionsで自動実行（mainブランチへのpush時）、または手動で`workflow_dispatch`

```sh
make deploy  # amd64環境でのみ実行可能
make plan    # Terraform plan確認
```

### IaC構成

| ファイル | 役割 |
|---------|------|
| `compose.yaml` | ローカル開発 |
| `docker-bake.hcl` | 本番ビルド定義 |
| `Makefile` | コマンド統一 |
| `.github/workflows/deploy.yml` | CI/CD |
| `terraform/` | GCPインフラ定義 |

### アーキテクチャ制約

- devcontainer: ARM (aarch64)
- Cloud Run: AMD64 (x86_64)
- ErlangはQEMUエミュレーション非対応 → ローカルからamd64ビルド不可
- 本番デプロイはGitHub Actions（amd64ネイティブ）で実行
