@echo on
setlocal enabledelayedexpansion

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

REM Set the correct target for ARM64 builds
if "%CARGO_BUILD_TARGET%"=="aarch64-pc-windows-msvc" (
    cargo build --release --target aarch64-pc-windows-msvc
) else (
    cargo build --release
)

if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

REM Copy from the correct target directory
if "%CARGO_BUILD_TARGET%"=="aarch64-pc-windows-msvc" (
    copy target\aarch64-pc-windows-msvc\release\codex.exe "%PREFIX%\bin\"
) else (
    copy target\release\codex.exe "%PREFIX%\bin\"
)
