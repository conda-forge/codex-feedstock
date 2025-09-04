#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CFLAGS="$CFLAGS -D_GNU_SOURCE"
export CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

# Determine the Rust target from conda-forge environment variables
if [ -n "${CARGO_BUILD_TARGET:-}" ]; then
    RUST_TARGET="${CARGO_BUILD_TARGET}"
elif [ -n "${HOST:-}" ]; then
    # Map conda-forge HOST to Rust target
    case "${HOST}" in
        "arm64-apple-darwin"*|"aarch64-apple-darwin"*)
            RUST_TARGET="aarch64-apple-darwin"
            ;;
        "x86_64-apple-darwin"*)
            RUST_TARGET="x86_64-apple-darwin"
            ;;
        "x86_64-unknown-linux-gnu"*|"x86_64-linux-gnu"*)
            RUST_TARGET="x86_64-unknown-linux-gnu"
            ;;
        *)
            RUST_TARGET=""
            ;;
    esac
elif [ -n "${target_platform:-}" ]; then
    # Fallback to target_platform mapping
    case "${target_platform}" in
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
else
    RUST_TARGET=""
fi

# Build with target-specific compilation
if [ -n "${RUST_TARGET}" ]; then
    # Only use rustup for cross-compilation (when build != target platform)
    if command -v rustup >/dev/null 2>&1; then
        rustup target add "${RUST_TARGET}" || true
    fi
    
    # Temporarily rename rust-toolchain.toml to prevent it from overriding cross-compilation
    if [ -f "rust-toolchain.toml" ]; then
        mv rust-toolchain.toml rust-toolchain.toml.bak
    fi
    
    cargo build --release --target "${RUST_TARGET}"
    
    # Restore rust-toolchain.toml
    if [ -f "rust-toolchain.toml.bak" ]; then
        mv rust-toolchain.toml.bak rust-toolchain.toml
    fi
    
    TARGET_DIR="target/${RUST_TARGET}/release"
else
    cargo build --release
    TARGET_DIR="target/release"
fi

mkdir -p "$PREFIX/bin"
install -m0755 "${TARGET_DIR}/codex" "$PREFIX/bin/"
