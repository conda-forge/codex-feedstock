#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ ${OSTYPE} == "linux"* ]]; then
  # Limit the number of parallel jobs to avoid OOM errors on GitHub Actions runners
  export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
fi

if [[ ${OSTYPE} == "linux"* && "${build_platform:-}" != "${target_platform:-}" ]]; then
  export PKG_CONFIG_ALLOW_CROSS=1
  export OPENSSL_DIR="${PREFIX}"
fi

# cargo-auditable compat
sed -i.bak -e 's/"build",/"auditable","build",/g' scripts/codex_package/cargo.py
# build
just assemble-codex-package --cargo-profile release --package-dir out --target "${CARGO_BUILD_TARGET}"

# install artifacts
cp -r out/* "${PREFIX}/"

# Pixi: prevent CONDA_PREFIX from leaking into sandboxed processes
mkdir -p "${PREFIX}/etc/pixi/codex"
touch "${PREFIX}/etc/pixi/codex/global-ignore-conda-prefix"

cd codex-rs
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml

mkdir -p $PREFIX/share/zsh/site-functions $PREFIX/share/bash-completion/completions $PREFIX/share/fish/vendor_completions.d
$PREFIX/bin/codex completion zsh >$PREFIX/share/zsh/site-functions/_codex
$PREFIX/bin/codex completion bash >$PREFIX/share/bash-completion/completions/codex
$PREFIX/bin/codex completion fish >$PREFIX/share/fish/vendor_completions.d/codex.fish
