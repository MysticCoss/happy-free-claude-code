#!/usr/bin/env pwsh
# Wrapper: strip ANTHROPIC_* vars, set proxy env, then run happy.
# Usage: ./happy-fcc.ps1 [--1m] [happy args...]
#
#   --1m    Disable the 260k auto-compact window, allowing the full 1M
#           context window of the underlying model.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$HappyArgs
)

$ErrorActionPreference = "Stop"

# ---- parse flags ----
$OneM = $false
$RemainingArgs = @()

foreach ($arg in $HappyArgs) {
    if ($arg -eq "--1m") {
        $OneM = $true
    } else {
        $RemainingArgs += $arg
    }
}

# ---- proxy config (reads ~/.fcc/.env or $env:USERPROFILE\.fcc\.env, defaults) ----
$Port = "8082"
$AuthToken = ""

$FccEnvFile = if ($env:HOME) {
    Join-Path $env:HOME ".fcc\.env"
} elseif ($env:USERPROFILE) {
    Join-Path $env:USERPROFILE ".fcc\.env"
} else {
    $null
}

if ($FccEnvFile -and (Test-Path $FccEnvFile)) {
    Get-Content $FccEnvFile | ForEach-Object {
        if ($_ -match '^PORT\s*=\s*(\d+)') {
            $Port = $matches[1]
        }
        if ($_ -match '^ANTHROPIC_AUTH_TOKEN\s*=\s*(.+)') {
            $AuthToken = $matches[1].Trim()
        }
    }
}

# ---- strip ALL ANTHROPIC_* from the env (mimics _claude_child_env) ----
Get-ChildItem env: | Where-Object { $_.Name -like "ANTHROPIC_*" } | ForEach-Object {
    Remove-Item -Path "env:$($_.Name)" -ErrorAction SilentlyContinue
}

# ---- build arg array ----
$HappyCmd = @(
    "happy",
    "--claude-env", "ANTHROPIC_BASE_URL=http://127.0.0.1:$Port",
    "--claude-env", "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1",
    "--claude-env", "API_TIMEOUT_MS=1200000",
    "--claude-env", "CLAUDE_STREAM_IDLE_TIMEOUT_MS=180000"
)

# Conditional compact window (omitted with --1m)
if (-not $OneM) {
    $HappyCmd += @("--claude-env", "CLAUDE_CODE_AUTO_COMPACT_WINDOW=260000")
}

# Optional auth token
if ($AuthToken) {
    $HappyCmd += @("--claude-env", "ANTHROPIC_AUTH_TOKEN=$AuthToken")
}

$HappyCmd += $RemainingArgs

# ---- exec ----
& $HappyCmd[0] $HappyCmd[1..$HappyCmd.Length]
exit $LASTEXITCODE
