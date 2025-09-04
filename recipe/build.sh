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
    echo
    echo "[DEBUG] Environment variables before setup:"
    echo "CARGO_BUILD_TARGET=${CARGO_BUILD_TARGET:-<unset>}"
    echo "RUST_TARGET=${RUST_TARGET}"
    echo "target_platform=${target_platform:-<unset>}"
    echo "HOST=${HOST:-<unset>}"
    echo
    
    # Only use rustup for cross-compilation (when build != target platform)
    if command -v rustup >/dev/null 2>&1; then
        # Add Rust target if it doesn't exist
        rustup target add "${RUST_TARGET}" || true
        # Set the target toolchain as default to avoid conflicts
        rustup toolchain install "stable-${RUST_TARGET}" || true
        rustup default "stable-${RUST_TARGET}" || true
        rustup update
        
        echo "[DEBUG] Rust toolchain info:"
        rustup show
        echo
        echo "[DEBUG] Available Rust targets:"
        rustup target list --installed
        echo
    fi
    
    # Create .cargo/config.toml to explicitly force the target
    mkdir -p .cargo
    cat > .cargo/config.toml << EOF
[build]
target = "${RUST_TARGET}"
EOF
    
    echo "[DEBUG] Contents of .cargo/config.toml:"
    cat .cargo/config.toml
    echo
    
    # Clear any existing CARGO_BUILD_TARGET that might override our config
    unset CARGO_BUILD_TARGET
    echo "[DEBUG] After clearing CARGO_BUILD_TARGET:"
    echo "CARGO_BUILD_TARGET=${CARGO_BUILD_TARGET:-<unset>}"
    echo
    
    cargo build --release
    TARGET_DIR="target/${RUST_TARGET}/release"
    
    echo "[DEBUG] Binary info:"
    if [ -f "${TARGET_DIR}/codex" ]; then
        echo "Binary exists at: ${TARGET_DIR}/codex"
        ls -la "${TARGET_DIR}/codex"
        if command -v file >/dev/null 2>&1; then
            echo "Architecture check:"
            file "${TARGET_DIR}/codex"
        fi
    else
        echo "ERROR: Binary not found at ${TARGET_DIR}/codex"
    fi
    echo
else
    echo "Building for default target"
    cargo build --release
    TARGET_DIR="target/release"
fi

mkdir -p "$PREFIX/bin"
install -m0755 "${TARGET_DIR}/codex" "$PREFIX/bin/"
