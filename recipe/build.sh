#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CFLAGS="$CFLAGS -D_GNU_SOURCE"
export CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

# Build with target-specific compilation if CARGO_BUILD_TARGET is set
if [ -n "${CARGO_BUILD_TARGET:-}" ]; then
    echo "Building for Rust target: ${CARGO_BUILD_TARGET}"
    # Add Rust target if it doesn't exist
    rustup target add "${CARGO_BUILD_TARGET}" || true
    cargo build --release --target "${CARGO_BUILD_TARGET}"
    TARGET_DIR="target/${CARGO_BUILD_TARGET}/release"
else
    echo "Building for default target"
    cargo build --release
    TARGET_DIR="target/release"
fi

mkdir -p "$PREFIX/bin"
install -m0755 "${TARGET_DIR}/codex" "$PREFIX/bin/"
