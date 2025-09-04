@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Build with target-specific compilation if CARGO_BUILD_TARGET is set
if defined CARGO_BUILD_TARGET (
    echo Building for Rust target: %CARGO_BUILD_TARGET%
    REM Add Rust target if it doesn't exist
    rustup target add %CARGO_BUILD_TARGET% 2>nul || echo Target already exists
    cargo build --release --target %CARGO_BUILD_TARGET%
    set "TARGET_DIR=target\%CARGO_BUILD_TARGET%\release"
) else (
    echo Building for default target
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
