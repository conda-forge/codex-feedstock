#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CFLAGS="$CFLAGS -D_GNU_SOURCE"
export CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

# Map conda-forge target platform to Rust target
case "${target_platform:-}" in
    "osx-arm64")
        RUST_TARGET="aarch64-apple-darwin"
        ;;
    "osx-64")
        RUST_TARGET="x86_64-apple-darwin"
        ;;
    "linux-64")
        RUST_TARGET="x86_64-unknown-linux-gnu"
        ;;
    *)
        RUST_TARGET=""
        ;;
esac

# Build with target-specific compilation
if [ -n "${RUST_TARGET}" ]; then
    echo "Building for Rust target: ${RUST_TARGET}"
    # Add Rust target if it doesn't exist
    rustup target add "${RUST_TARGET}" || true
    cargo build --release --target "${RUST_TARGET}"
    TARGET_DIR="target/${RUST_TARGET}/release"
else
    echo "Building for default target"
    cargo build --release
    TARGET_DIR="target/release"
fi

mkdir -p "$PREFIX/bin"
install -m0755 "${TARGET_DIR}/codex" "$PREFIX/bin/"
