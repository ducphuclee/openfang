# syntax=docker/dockerfile:1

FROM rust:1-bookworm AS builder
WORKDIR /build

RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev

COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main(){}" > src/main.rs
RUN cargo build --release

COPY . .
RUN cargo build --release --bin openfang

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y ca-certificates libssl3 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/openfang /usr/local/bin/

ENV OPENFANG_HOME=/data
VOLUME /data
EXPOSE 4200

ENTRYPOINT ["openfang"]
CMD ["start"]
