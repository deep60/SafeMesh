# ─── Build Stage ───
FROM rust:1.75-bookworm AS builder

WORKDIR /app

# Cache dependencies
COPY Cargo.toml Cargo.lock* ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs && echo "" > src/lib.rs
RUN cargo build --release 2>/dev/null || true

# Build actual application
COPY src/ ./src/
COPY .env ./
RUN cargo build --release

# ─── Runtime Stage ───
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r safemesh && useradd -r -g safemesh safemesh

WORKDIR /app

COPY --from=builder /app/target/release/Backend ./safemesh-backend
COPY --from=builder /app/.env ./.env
COPY ../Database/migrations/ ./migrations/

RUN mkdir -p /app/data && chown -R safemesh:safemesh /app

USER safemesh

ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE_URL=sqlite:/app/data/vpn.db

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/api/v1/health || exit 1

CMD ["./safemesh-backend"]
