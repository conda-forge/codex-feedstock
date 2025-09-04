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
    echo.
    echo [DEBUG] Environment variables before setup:
    echo CARGO_BUILD_TARGET=%CARGO_BUILD_TARGET%
    echo RUST_TARGET=%RUST_TARGET%
    echo target_platform=%target_platform%
    echo.
    
    REM Add Rust target if it doesn't exist
    rustup target add %RUST_TARGET% 2>nul || echo Target already exists
    REM Set the target toolchain as default to avoid conflicts
    rustup toolchain install stable-%RUST_TARGET% 2>nul || echo Toolchain already exists
    rustup default stable-%RUST_TARGET% 2>nul || echo Default already set
    rustup update
    
    echo [DEBUG] Rust toolchain info:
    rustup show
    echo.
    echo [DEBUG] Available Rust targets:
    rustup target list --installed
    echo.
    
    REM Create .cargo/config.toml to explicitly force the target
    if not exist .cargo mkdir .cargo
    echo [build] > .cargo\config.toml
    echo target = "%RUST_TARGET%" >> .cargo\config.toml
    
    echo [DEBUG] Contents of .cargo\config.toml:
    type .cargo\config.toml
    echo.
    
    REM Clear any existing CARGO_BUILD_TARGET that might override our config
    set CARGO_BUILD_TARGET=
    echo [DEBUG] After clearing CARGO_BUILD_TARGET:
    echo CARGO_BUILD_TARGET=%CARGO_BUILD_TARGET%
    echo.
    
    cargo build --release
    set "TARGET_DIR=target\%RUST_TARGET%\release"
    
    echo [DEBUG] Binary info:
    if exist "%TARGET_DIR%\codex.exe" (
        echo Binary exists at: %TARGET_DIR%\codex.exe
        dir "%TARGET_DIR%\codex.exe"
    ) else (
        echo ERROR: Binary not found at %TARGET_DIR%\codex.exe
    )
    echo.
) else (
    echo Building for default target
    cargo build --release
    set "TARGET_DIR=target\release"
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
copy "%TARGET_DIR%\codex.exe" "%PREFIX%\bin\"
