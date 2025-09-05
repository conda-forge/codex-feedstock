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
    echo "[DEBUG] Cross-compilation detected for target: ${RUST_TARGET}"
    echo "[DEBUG] Environment variables:"
    echo "[DEBUG] CARGO_BUILD_TARGET=${CARGO_BUILD_TARGET:-<unset>}"
    echo "[DEBUG] target_platform=${target_platform:-<unset>}"
    echo "[DEBUG] HOST=${HOST:-<unset>}"
    echo "[DEBUG] Current directory: $(pwd)"
    echo
    
    # Only use rustup for cross-compilation (when build != target platform)
    if command -v rustup >/dev/null 2>&1; then
        echo "[DEBUG] Adding Rust target ${RUST_TARGET}"
        rustup target add "${RUST_TARGET}" || true
    fi
    
    echo "[DEBUG] Checking for rust-toolchain files"
    if [ -f "rust-toolchain.toml" ]; then
        echo "[DEBUG] Found rust-toolchain.toml, contents:"
        cat rust-toolchain.toml
        echo "[DEBUG] DELETING rust-toolchain.toml to prevent override"
        rm rust-toolchain.toml
    else
        echo "[DEBUG] No rust-toolchain.toml found"
    fi
    
    if [ -f "rust-toolchain" ]; then
        echo "[DEBUG] Found rust-toolchain file, deleting it too"
        rm rust-toolchain
    fi
    
    echo "[DEBUG] Current Rust toolchain info:"
    if command -v rustup >/dev/null 2>&1; then
        rustup show
        echo
        echo "[DEBUG] Available targets:"
        rustup target list --installed
        echo
    fi
    
    echo "[DEBUG] Building for target: ${RUST_TARGET}"
    cargo build --release --target "${RUST_TARGET}"
    echo "[DEBUG] Build completed for target: ${RUST_TARGET}"
    
    echo "[DEBUG] Checking output directory:"
    ls -la "target/${RUST_TARGET}/release/codex" || echo "Binary not found!"
    if command -v file >/dev/null 2>&1; then
        echo "[DEBUG] Binary architecture:"
        file "target/${RUST_TARGET}/release/codex"
    fi
    
    TARGET_DIR="target/${RUST_TARGET}/release"
else
    echo "[DEBUG] No cross-compilation, using default target"
    cargo build --release
    TARGET_DIR="target/release"
fi

mkdir -p "$PREFIX/bin"
install -m0755 "${TARGET_DIR}/codex" "$PREFIX/bin/"
