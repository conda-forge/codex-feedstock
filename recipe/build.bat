@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Use cargo install with explicit target for cross-compilation (this needed, otherwise linking errors occurs)
if defined CARGO_BUILD_TARGET (
    echo Building for target: %CARGO_BUILD_TARGET%
    cargo install --locked --no-track --bins --root "%PREFIX%" --path cli --target %CARGO_BUILD_TARGET%
) else (
    cargo install --locked --no-track --bins --root "%PREFIX%" --path cli
)
