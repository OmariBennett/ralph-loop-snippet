#!/usr/bin/env pwsh
# test-ralph-once.ps1 - HITL single-iteration runner
#
# Run once, watch what Claude does, intervene when needed.
# Refine the PRD or this prompt between runs before going AFK.
#
# Usage (from this directory or the repo root):
#   powershell -ExecutionPolicy Bypass -File .\test\test-ralph-once.ps1
#   powershell -ExecutionPolicy Bypass -File .\test-ralph-once.ps1
#
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve project directory (works regardless of where you call from)
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# File names (relative - used for @file references to claude)
$prdRelative      = "test-prd.json"
$progressRelative = "test-progress.txt"
$prdAbsolute      = Join-Path $projectDir $prdRelative

if (-not (Test-Path $prdAbsolute)) {
    Write-Error "PRD not found: $prdAbsolute"
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error "claude CLI not found. Install from: https://claude.ai/download"
    exit 1
}

Write-Host "==> Ralph HITL - single iteration for: test"
Write-Host "    Project: $projectDir"
Write-Host ""

# IMPORTANT: Push-Location so claude's @file references resolve correctly.
# Claude Code's @filename syntax is relative to the current working directory.
Push-Location $projectDir
try {
    $prompt = "@$prdRelative @$progressRelative
1. Decide which task to work on next - highest priority by YOUR judgment, not list order.
2. Check feedback loops (types, tests, lint) before and after changes.
3. Append your progress to ${progressRelative} in this format:
   [Iteration N | YYYY-MM-DD] Task | Files changed | Key decisions | Blockers
4. Make a git commit of that feature with a descriptive message.
ONLY WORK ON A SINGLE FEATURE PER RUN.
If all features in the PRD have passes=true and all feedback loops are green,
output exactly: <promise>COMPLETE</promise>"

    $result = claude -p $prompt
    Write-Host $result

    if ($result -match '<promise>COMPLETE</promise>') {
        Write-Host ""
        Write-Host "==> COMPLETE - all features done. Delete progress.txt when your sprint is over."
    }
} finally {
    Pop-Location
}
