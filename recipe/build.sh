#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CFLAGS="$CFLAGS -D_GNU_SOURCE"
export CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

# Determine the Rust target from conda-forge environment variables
if [ -n "${CARGO_BUILD_TARGET:-}" ]; then
    RUST_TARGET="${CARGO_BUILD_TARGET}"
    echo "Using CARGO_BUILD_TARGET: ${RUST_TARGET}"
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
            echo "Unknown HOST: ${HOST}, using default target"
            ;;
    esac
    if [ -n "${RUST_TARGET}" ]; then
        echo "Mapped HOST '${HOST}' to Rust target: ${RUST_TARGET}"
    fi
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
    if [ -n "${RUST_TARGET}" ]; then
        echo "Mapped target_platform '${target_platform}' to Rust target: ${RUST_TARGET}"
    fi
else
    RUST_TARGET=""
    echo "No cross-compilation variables found, using default target"
fi

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
