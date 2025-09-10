#!/usr/bin/env bash

set -euo pipefail

# Ensure expected Node-style layout exists so Codex can self-resolve
# when installed via Pixi/Conda without an npm tree.

: "${PREFIX:?PREFIX not set}"

EXPECTED_DIR="$PREFIX/lib/node_modules/@openai/codex/bin"
ACTUAL_BIN="$PREFIX/bin/codex"

mkdir -p "$EXPECTED_DIR"

if [ ! -x "$ACTUAL_BIN" ]; then
  # Nothing to do if the binary is missing
  exit 0
fi

# Candidate binary names used by the Node wrapper across platforms
NAMES=(
  codex-aarch64-apple-darwin
  codex-x86_64-apple-darwin
  codex-aarch64-unknown-linux-gnu
  codex-x86_64-unknown-linux-gnu
  codex-aarch64-unknown-linux-musl
  codex-x86_64-unknown-linux-musl
)

for name in "${NAMES[@]}"; do
  target="$EXPECTED_DIR/$name"
  if [ -e "$target" ]; then
    continue
  fi
  # Prefer symlink; fall back to copy if symlinks are not allowed
  if ln -sfn "$ACTUAL_BIN" "$target" 2>/dev/null; then
    :
  else
    cp -f "$ACTUAL_BIN" "$target"
  fi
done

exit 0

