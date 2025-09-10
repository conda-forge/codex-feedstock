#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export CFLAGS="$CFLAGS -D_GNU_SOURCE"
export CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

# Use cargo install with explicit target for cross-compilation (this is needed, otherwise linking fails)
if [ -n "${CARGO_BUILD_TARGET:-}" ]; then
    echo "Building for target: ${CARGO_BUILD_TARGET}"
    cargo install --locked --no-track --bins --root "${PREFIX}" --path cli --target "${CARGO_BUILD_TARGET}"
else
    cargo install --locked --no-track --bins --root "${PREFIX}" --path cli
fi

# Recreate Node-style layout so the JS wrapper can locate platform-tagged binaries without a post-link script
EXPECTED_DIR="${PREFIX}/lib/node_modules/@openai/codex/bin"
ACTUAL_BIN="${PREFIX}/bin/codex"
mkdir -p "${EXPECTED_DIR}"

if [ -x "${ACTUAL_BIN}" ]; then
    NAMES=(
        codex-aarch64-apple-darwin
        codex-x86_64-apple-darwin
        codex-aarch64-unknown-linux-gnu
        codex-x86_64-unknown-linux-gnu
        codex-aarch64-unknown-linux-musl
        codex-x86_64-unknown-linux-musl
    )
    for name in "${NAMES[@]}"; do
        target="${EXPECTED_DIR}/${name}"
        if [ -e "${target}" ]; then
            continue
        fi
        if ln -sfn "${ACTUAL_BIN}" "${target}" 2>/dev/null; then
            :
        else
            cp -f "${ACTUAL_BIN}" "${target}"
        fi
    done
fi
