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
    echo [DEBUG] Cross-compilation detected for target: %RUST_TARGET%
    echo [DEBUG] Environment variables:
    echo [DEBUG] CARGO_BUILD_TARGET=%CARGO_BUILD_TARGET%
    echo [DEBUG] target_platform=%target_platform%
    echo [DEBUG] Current directory: %cd%
    echo.
    
    REM Add Rust target if it doesn't exist
    echo [DEBUG] Adding Rust target %RUST_TARGET%
    rustup target add %RUST_TARGET% 2>nul || echo Target already exists
    
    echo [DEBUG] Checking for rust-toolchain files
    if exist rust-toolchain.toml (
        echo [DEBUG] Found rust-toolchain.toml, contents:
        type rust-toolchain.toml
        echo [DEBUG] DELETING rust-toolchain.toml to prevent override
        del rust-toolchain.toml
    ) else (
        echo [DEBUG] No rust-toolchain.toml found
    )
    
    if exist rust-toolchain (
        echo [DEBUG] Found rust-toolchain file, deleting it too
        del rust-toolchain
    )
    
    echo [DEBUG] Current Rust toolchain info:
    rustup show
    echo.
    
    echo [DEBUG] Available targets:
    rustup target list --installed
    echo.
    
    echo [DEBUG] Building for target: %RUST_TARGET%
    cargo build --release --target %RUST_TARGET%
    echo [DEBUG] Build completed for target: %RUST_TARGET%
    
    echo [DEBUG] Checking output directory:
    dir target\%RUST_TARGET%\release\codex.exe
    
    set "TARGET_DIR=target\%RUST_TARGET%\release"
) else (
    echo [DEBUG] No cross-compilation, using default target
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
