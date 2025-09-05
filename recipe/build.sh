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
