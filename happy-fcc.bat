@echo off
REM Wrapper: strip ANTHROPIC_* vars, set proxy env, then run happy.
REM Usage: happy-fcc.bat [--1m] [happy args...]
REM
REM   --1m    Disable the 260k auto-compact window, allowing the full 1M
REM           context window of the underlying model.

setlocal enabledelayedexpansion

REM ---- defaults ----
set PORT=8082
set AUTH_TOKEN=
set ONE_M=0

REM ---- read ~/.fcc/.env if present ----
if exist "%USERPROFILE%\.fcc\.env" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%USERPROFILE%\.fcc\.env") do (
        set "_key=%%a"
        set "_key=!_key: =!"
        if "!_key!"=="PORT" (
            set "PORT=%%b"
            set "PORT=!PORT: =!"
        )
        if "!_key!"=="ANTHROPIC_AUTH_TOKEN" (
            set "AUTH_TOKEN=%%b"
        )
    )
)

REM ---- strip ALL ANTHROPIC_* env vars ----
for /f "tokens=1 delims==" %%a in ('set ANTHROPIC_ 2^>nul') do (
    set "%%a="
)

REM ---- parse --1m flag ----
set HAPPY_CMD=happy
set HAPPY_ARGS=
:parse
if "%~1"=="" goto run
if "%~1"=="--1m" (
    set ONE_M=1
    shift
    goto parse
)
set HAPPY_ARGS=%HAPPY_ARGS% %1
shift
goto parse

:run
REM ---- build base env args ----
set ENV_ARGS=--claude-env "ANTHROPIC_BASE_URL=http://127.0.0.1:%PORT%"
set ENV_ARGS=%ENV_ARGS% --claude-env "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1"
set ENV_ARGS=%ENV_ARGS% --claude-env "API_TIMEOUT_MS=1200000"
set ENV_ARGS=%ENV_ARGS% --claude-env "CLAUDE_STREAM_IDLE_TIMEOUT_MS=180000"

REM ---- conditional compact window ----
if %ONE_M%==0 (
    set ENV_ARGS=%ENV_ARGS% --claude-env "CLAUDE_CODE_AUTO_COMPACT_WINDOW=260000"
)

REM ---- optional auth token ----
if not "%AUTH_TOKEN%"=="" (
    set ENV_ARGS=%ENV_ARGS% --claude-env "ANTHROPIC_AUTH_TOKEN=%AUTH_TOKEN%"
)

happy %ENV_ARGS% %HAPPY_ARGS%
exit /b %ERRORLEVEL%
