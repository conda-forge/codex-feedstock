@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Map conda-forge target platform to Rust target
if "%target_platform%"=="win-arm64" (
    set "RUST_TARGET=aarch64-pc-windows-msvc"
) else if "%target_platform%"=="win-64" (
    set "RUST_TARGET=x86_64-pc-windows-msvc"
) else (
    set "RUST_TARGET="
)

REM Build with target-specific compilation
if defined RUST_TARGET (
    echo Building for Rust target: %RUST_TARGET%
    REM Add Rust target if it doesn't exist
    rustup target add %RUST_TARGET% 2>nul || echo Target already exists
    cargo build --release --target %RUST_TARGET%
    set "TARGET_DIR=target\%RUST_TARGET%\release"
) else (
    echo Building for default target
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
