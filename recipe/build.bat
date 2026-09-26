@echo on
setlocal enabledelayedexpansion

@rem Avoid Windows path-length issue breaking Cargo
for %%I in ("%SRC_DIR%") do set DRIVE_LETTER=%%~dI
set "CARGO_TARGET_DIR=%DRIVE_LETTER%\cd"
set "CARGO_HOME=%DRIVE_LETTER%\ch"

if not defined CARGO_BUILD_TARGET (
    if "%target_platform%"=="win-arm64" (
        set "CARGO_BUILD_TARGET=aarch64-pc-windows-msvc"
    ) else if "%target_platform%"=="win-64" (
        set "CARGO_BUILD_TARGET=x86_64-pc-windows-msvc"
    )
)

@rem cargo-auditable compat
sed -i.bak -e 's/"build",/"auditable","build",/g' scripts/codex_package/cargo.py
@rem build
just assemble-codex-package --cargo-profile release --package-dir out --target "%CARGO_BUILD_TARGET%"
if %ERRORLEVEL% neq 0 exit 1

@rem install artifacts
robocopy "out/" "%PREFIX%" /E /NFL /NDL /NJH /NJS /NC /NS /NP

REM Pixi: prevent CONDA_PREFIX from leaking into sandboxed processes
set "MARKER_DIR=%PREFIX%\etc\pixi\codex"
if not exist "%MARKER_DIR%" (
    mkdir "%MARKER_DIR%" 2>nul
)
type nul > "%MARKER_DIR%\global-ignore-conda-prefix"

cd codex-rs
cargo-bundle-licenses --format yaml --output ..\THIRDPARTY.yml

endlocal
exit /b 0
