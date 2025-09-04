@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Determine the Rust target based on conda-forge environment variables
if defined CARGO_BUILD_TARGET (
    set "RUST_TARGET=%CARGO_BUILD_TARGET%"
    echo Using CARGO_BUILD_TARGET: %RUST_TARGET%
) else if "%target_platform%"=="win-arm64" (
    set "RUST_TARGET=aarch64-pc-windows-msvc"
    echo Detected Windows ARM64 cross-compilation, using: %RUST_TARGET%
) else if "%target_platform%"=="win-64" (
    set "RUST_TARGET=x86_64-pc-windows-msvc"
    echo Detected Windows x64, using: %RUST_TARGET%
) else (
    set "RUST_TARGET="
    echo Using default Rust target
)

REM Build with target-specific compilation
if defined RUST_TARGET (
    echo Building for Rust target: %RUST_TARGET%
    REM Add Rust target if it doesn't exist
    rustup target add %RUST_TARGET% 2>nul || echo Target already exists
    REM Set the target toolchain as default to avoid conflicts
    rustup toolchain install stable-%RUST_TARGET% 2>nul || echo Toolchain already exists
    rustup default stable-%RUST_TARGET% 2>nul || echo Default already set
    rustup update
    REM Create .cargo/config.toml to explicitly force the target
    if not exist .cargo mkdir .cargo
    echo [build] > .cargo\config.toml
    echo target = "%RUST_TARGET%" >> .cargo\config.toml
    cargo build --release
    set "TARGET_DIR=target\%RUST_TARGET%\release"
) else (
    echo Building for default target
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
