# syntax=docker/dockerfile:1

ARG TARGETARCH=amd64

FROM --platform=linux/amd64 joseluisq/docker-osxcross:1.0.0-beta.2 AS base-amd64
FROM --platform=linux/arm64 joseluisq/docker-osxcross:1.0.0-beta.1 AS base-arm64

FROM base-${TARGETARCH}

LABEL version="${VERSION}" \
    description="Docker image for cross-compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    maintainer="Jose Quintana <joseluisq.net>"

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

ARG TOOLCHAIN=1.93.1
ARG TARGETARCH=amd64

RUN set -eux \
    && if [ "$TARGETARCH" = "amd64" ]; then \
        dpkg --add-architecture arm64; \
    else \
        dpkg --add-architecture amd64; \
    fi \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && if [ "$TARGETARCH" = "amd64" ]; then \
        DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
            musl-dev \
            musl-dev:arm64 \
            musl-tools \
            gcc-aarch64-linux-gnu \
            g++-aarch64-linux-gnu; \
    else \
        DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
            musl-dev \
            musl-dev:amd64 \
            musl-tools \
            gcc-x86-64-linux-gnu \
            g++-x86-64-linux-gnu; \
    fi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

RUN set -eux \
    && ln -s "/usr/bin/g++" "/usr/bin/musl-g++" \
    && mkdir -p /root/libs /root/src \
    && true

ENV PATH=/root/.cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

ENV TARGET=musl
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_ALL_STATIC=1
ENV RUST_MIN_STACK=16777216

RUN set -eux \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain=$TOOLCHAIN \
    && rustup target add \
        aarch64-apple-darwin \
        aarch64-unknown-linux-gnu \
        aarch64-unknown-linux-musl \
        x86_64-apple-darwin \
        x86_64-unknown-linux-musl \
        x86_64-unknown-linux-gnu \
    && true

COPY docker/amd64/base/cargo.toml /tmp/cargo-amd64.toml
COPY docker/arm64/base/cargo.toml /tmp/cargo-arm64.toml

RUN set -eux \
    && mkdir -p /root/.cargo \
    && if [ "$TARGETARCH" = "amd64" ]; then \
        cp /tmp/cargo-amd64.toml /root/.cargo/config.toml; \
    else \
        cp /tmp/cargo-arm64.toml /root/.cargo/config.toml; \
    fi \
    && rm /tmp/cargo-amd64.toml /tmp/cargo-arm64.toml \
    && true

WORKDIR /root/src

CMD ["bash"]
