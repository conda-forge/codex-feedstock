@echo off
setlocal enableextensions

REM Ensure expected Node-style layout exists so Codex can self-resolve
if "%PREFIX%"=="" (
  echo PREFIX not set
  exit /b 0
)

set "EXPECTED_DIR=%PREFIX%\lib\node_modules\@openai\codex\bin"
set "ACTUAL_BIN=%PREFIX%\bin\codex.exe"

if not exist "%EXPECTED_DIR%" (
  mkdir "%EXPECTED_DIR%" 2>nul
)

if not exist "%ACTUAL_BIN%" (
  exit /b 0
)

REM Candidate binary names used by the Node wrapper on Windows
for %%N in (
  codex-x86_64-pc-windows-msvc.exe
  codex-aarch64-pc-windows-msvc.exe
) do (
  if not exist "%EXPECTED_DIR%\%%N" (
    copy /Y "%ACTUAL_BIN%" "%EXPECTED_DIR%\%%N" >nul
  )
)

exit /b 0

