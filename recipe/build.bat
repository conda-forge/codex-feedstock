@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Determine the Rust target based on conda-forge environment variables
if defined CARGO_BUILD_TARGET (
    set "RUST_TARGET=%CARGO_BUILD_TARGET%"
) else if "%target_platform%"=="win-arm64" (
    set "RUST_TARGET=aarch64-pc-windows-msvc"
) else if "%target_platform%"=="win-64" (
    set "RUST_TARGET=x86_64-pc-windows-msvc"
) else (
    set "RUST_TARGET="
)

REM Build with target-specific compilation
if defined RUST_TARGET (
    REM Add Rust target if it doesn't exist
    rustup target add %RUST_TARGET% 2>nul || echo Target already exists
    
    REM Temporarily rename rust-toolchain.toml to prevent it from overriding cross-compilation
    if exist rust-toolchain.toml (
        ren rust-toolchain.toml rust-toolchain.toml.bak
    )
    
    cargo build --release --target %RUST_TARGET%
    
    REM Restore rust-toolchain.toml
    if exist rust-toolchain.toml.bak (
        ren rust-toolchain.toml.bak rust-toolchain.toml
    )
    
    set "TARGET_DIR=target\%RUST_TARGET%\release"
) else (
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
