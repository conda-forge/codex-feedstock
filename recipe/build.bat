@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml
cargo install --locked --no-track --bins --root "%PREFIX%" --path cli
