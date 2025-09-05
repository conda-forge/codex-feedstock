@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

if not defined CARGO_BUILD_TARGET (
    if "%target_platform%"=="win-arm64" (
        set "CARGO_BUILD_TARGET=aarch64-pc-windows-msvc"
    ) else if "%target_platform%"=="win-64" (
        set "CARGO_BUILD_TARGET=x86_64-pc-windows-msvc"
    )
)

REM Use cargo install with explicit target for cross-compilation (this needed, otherwise linking errors occurs)
if defined CARGO_BUILD_TARGET (
    echo Building for target: %CARGO_BUILD_TARGET%
    cargo install --locked --no-track --bins --root "%PREFIX%" --path cli --target %CARGO_BUILD_TARGET%
) else (
    cargo install --locked --no-track --bins --root "%PREFIX%" --path cli
)
