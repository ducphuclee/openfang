# syntax=docker/dockerfile:1.4

# --- Stage 1: Build môi trường ---
FROM rust:1-slim-bookworm AS builder
WORKDIR /build

# Cài đặt các thư viện C cần thiết cho quá trình build
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# Copy toàn bộ source code vào
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
COPY xtask ./xtask
COPY agents ./agents
COPY packages ./packages

# TỐI ƯU Ở ĐÂY: Sử dụng cache mount cho registry của cargo và thư mục target
# Điều này giúp giữ lại các thư viện đã tải và các file đã biên dịch giữa các lần build
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/build/target \
    cargo build --release --bin openfang && \
    # Khéo léo copy file binary ra ngoài thư mục target (vì target đang bị cache mount)
    cp target/release/openfang /build/openfang

# --- Stage 2: Môi trường chạy (Runtime) ---
FROM debian:bookworm-slim

# Chỉ cài chứng chỉ bảo mật, image sẽ cực nhẹ
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Lấy duy nhất file thực thi từ bước build
COPY --from=builder /build/openfang /usr/local/bin/

# Copy thư mục agents vào theo đúng cấu trúc của bạn
COPY --from=builder /build/agents /opt/openfang/agents

# Thiết lập môi trường
EXPOSE 4200
VOLUME /data
ENV OPENFANG_HOME=/data

ENTRYPOINT ["openfang"]
CMD ["start"]
