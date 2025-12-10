@echo on
setlocal enabledelayedexpansion

REM Fix HOME for git config (CI sets it to Unix-style path that doesn't exist on Windows)
set "HOME=%USERPROFILE%"

REM Enable long paths for Git/libgit2 (required even if OS-level long paths are enabled)
git config --global core.longpaths true

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

REM Recreate Node-style layout so the Node wrapper can locate platform-tagged binaries
set "EXPECTED_DIR=%PREFIX%\lib\node_modules\@openai\codex\bin"
set "ACTUAL_BIN=%PREFIX%\bin\codex.exe"

if not exist "%EXPECTED_DIR%" (
    mkdir "%EXPECTED_DIR%" 2>nul
)

if exist "%ACTUAL_BIN%" (
    for %%N in ( 
        codex-x86_64-pc-windows-msvc.exe 
        codex-aarch64-pc-windows-msvc.exe 
    ) do (
        if not exist "%EXPECTED_DIR%\%%N" (
            copy /Y "%ACTUAL_BIN" "%EXPECTED_DIR%\%%N" >nul
        )
    )
)

endlocal
exit /b 0
