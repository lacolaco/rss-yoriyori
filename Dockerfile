# =============================================================================
# 本番用 Dockerfile - マルチステージビルド
# =============================================================================
#
# ビルド: docker build -t rss-yoriyori .
# 実行:   docker run -p 8080:8080 rss-yoriyori
#
# Gleam学習ポイント:
# - Gleam は Erlang (BEAM) にコンパイルされる
# - 実行時には Erlang VM (OTP) のみが必要
# - escript 形式で単一の実行可能ファイルを生成できる

# -----------------------------------------------------------------------------
# Stage 1: ビルド
# -----------------------------------------------------------------------------
FROM ghcr.io/gleam-lang/gleam:v1.13.0-erlang-alpine AS builder

WORKDIR /app

# 依存関係ファイルを先にコピー（キャッシュ効率化）
# gleam.toml と manifest.toml が変わらなければ、deps download はキャッシュされる
COPY gleam.toml manifest.toml ./

# 依存関係をダウンロード
RUN gleam deps download

# ソースコードをコピー
COPY src/ src/

# リリースビルド（escript形式）
# escript: Erlang の実行可能スクリプト形式
# 依存関係を含む単一ファイルが生成される
RUN gleam export erlang-shipment

# -----------------------------------------------------------------------------
# Stage 2: 実行環境
# -----------------------------------------------------------------------------
FROM erlang:28-alpine AS runtime

# セキュリティ: 非rootユーザーで実行
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

# ビルド成果物をコピー
# erlang-shipment は build/erlang-shipment/ に出力される
COPY --from=builder /app/build/erlang-shipment ./

# フィード設定ファイルをコピー
COPY feeds.json ./

# 所有権を変更
RUN chown -R app:app /app

# 非rootユーザーに切り替え
USER app

# Cloud Run は PORT 環境変数でポートを指定する
ENV PORT=8080
EXPOSE 8080

# エントリーポイント
# entrypoint.sh は gleam export erlang-shipment で生成される
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
