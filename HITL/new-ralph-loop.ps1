#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scaffolds a HITL Ralph loop for any project.

.DESCRIPTION
    Creates a folder with 5 files for a human-in-the-loop Ralph iteration workflow.
    Based on: https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum

    Copy this script (and the .bat) to any directory on your PATH to use globally.
    Example:
        Copy-Item .\new-ralph-loop.ps1 "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.ps1"
        Copy-Item .\new-ralph-loop.bat "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.bat"

.PARAMETER LoopPath
    Format: <name>/<name>  e.g. "todo/todo"
    Or just <name> shorthand e.g. "todo" (expands to "todo/todo")

.EXAMPLE
    .\new-ralph-loop.ps1 todo/todo
    .\new-ralph-loop.ps1 myapp
#>

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$LoopPath
)

if (-not $LoopPath) {
    Write-Host "Usage: new-ralph-loop <name>"
    Write-Host "       new-ralph-loop <namespace>/<name>"
    Write-Host ""
    Write-Host "Example: new-ralph-loop todo/todo"
    exit 1
}

# Parse: "name" -> shorthand for "name/name", or "namespace/name"
if ($LoopPath -match '^([^/\\]+)[/\\]([^/\\]+)$') {
    $dir  = $Matches[1]
    $name = $Matches[2]
} elseif ($LoopPath -match '^([^/\\]+)$') {
    $dir  = $Matches[1]
    $name = $Matches[1]
} else {
    Write-Error "Argument must be a name (e.g. foo) or namespace/name (e.g. foo/foo)"
    exit 1
}

# Create directory
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
}

# ---------------------------------------------------------------------------
# File templates - __NAME__ is replaced with $name at write time.
# Single-quoted here-strings prevent PowerShell from interpolating $variables
# inside the template content.
# ---------------------------------------------------------------------------

# 1. ralph-once.ps1 - HITL runner (Windows / PowerShell)
$ralphOncePs1 = @'
#!/usr/bin/env pwsh
# __NAME__-ralph-once.ps1 - HITL single-iteration runner
#
# Run once, watch what Claude does, intervene when needed.
# Refine the PRD or this prompt between runs before going AFK.
#
# Usage (from this directory or the repo root):
#   powershell -ExecutionPolicy Bypass -File .\__NAME__\__NAME__-ralph-once.ps1
#   powershell -ExecutionPolicy Bypass -File .\__NAME__-ralph-once.ps1
#
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve project directory (works regardless of where you call from)
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# File names (relative - used for @file references to claude)
$prdRelative      = "__NAME__-prd.json"
$progressRelative = "__NAME__-progress.txt"
$prdAbsolute      = Join-Path $projectDir $prdRelative

if (-not (Test-Path $prdAbsolute)) {
    Write-Error "PRD not found: $prdAbsolute"
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error "claude CLI not found. Install from: https://claude.ai/download"
    exit 1
}

Write-Host "==> Ralph HITL - single iteration for: __NAME__"
Write-Host "    Project: $projectDir"
Write-Host ""

# Auto-detect bash path (PS5-compatible: ?. null-conditional requires PS7+)
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd) { $bash = $bashCmd.Source } else { $bash = 'bash' }
$runnerSh = Join-Path $projectDir "__NAME__-ralph-once.sh"

# Capture commits before run to show what's new after
$commitsBefore = git log --oneline 2>$null

# IMPORTANT: Push-Location so claude's @file references resolve correctly.
# Claude Code's @filename syntax is relative to the current working directory.
Push-Location $projectDir
try {
    $prompt = "@$prdRelative @$progressRelative
1. Decide which task to work on next - highest priority by YOUR judgment, not list order.
2. Check feedback loops (types, tests, lint) before and after changes.
3. Append your progress to ${progressRelative} in this format:
   [Iteration N | YYYY-MM-DD] Task | Files changed | Key decisions | Blockers
4. Once all feedback loops pass for the completed feature, set its passes field to true in ${prdRelative}.
5. Make a git commit of that feature with a descriptive message.
ONLY WORK ON A SINGLE FEATURE PER RUN.
If all features in the PRD have passes=true and all feedback loops are green,
output exactly: <promise>COMPLETE</promise>"

    $result = claude -p --dangerously-skip-permissions $prompt
    Write-Host $result

    $commitsAfter = git log --oneline 2>$null
    $newCommits = $commitsAfter | Where-Object { $commitsBefore -notcontains $_ }
    if ($newCommits) {
        Write-Host ""
        Write-Host "==> Commits this run:"
        $newCommits | ForEach-Object { Write-Host "    $_" }
    }

    if ($result -match '<promise>COMPLETE</promise>') {
        Write-Host ""
        Write-Host "==> COMPLETE - all features done. Delete progress.txt when your sprint is over."
    }

    Write-Host ""
    Write-Host "Tip: to run the bash variant: & '$bash' '$runnerSh'"
} finally {
    Pop-Location
}
'@

# 2. ralph-once.sh - HITL runner (Git Bash / WSL / macOS / Linux)
$ralphOnceSh = @'
#!/usr/bin/env bash
# __NAME__-ralph-once.sh - HITL single-iteration runner (bash)
#
# Run once, watch what Claude does, intervene when needed.
#
# Usage:
#   bash __NAME__-ralph-once.sh
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD="__NAME__-prd.json"
PROGRESS="__NAME__-progress.txt"

if [[ ! -f "$DIR/$PRD" ]]; then
  echo "ERROR: $DIR/$PRD not found" >&2
  exit 1
fi

echo "==> Ralph HITL - single iteration for: __NAME__"
echo "    Project: $DIR"
echo ""

# cd into project dir so @file references resolve correctly for claude
cd "$DIR"

result=$(claude -p --dangerously-skip-permissions \
"@${PRD} @${PROGRESS}
1. Decide which task to work on next - highest priority by YOUR judgment, not list order.
2. Check feedback loops (types, tests, lint) before and after changes.
3. Append your progress to ${PROGRESS} in this format:
   [Iteration N | YYYY-MM-DD] Task | Files changed | Key decisions | Blockers
4. Make a git commit of that feature with a descriptive message.
ONLY WORK ON A SINGLE FEATURE PER RUN.
If all features in the PRD have passes=true and all feedback loops are green,
output exactly: <promise>COMPLETE</promise>")

echo "$result"

if echo "$result" | grep -q '<promise>COMPLETE</promise>'; then
  echo ""
  echo "==> COMPLETE - all features done. Delete progress.txt when your sprint is over."
fi
'@

# 3. prd.json
$prd = @'
{
  "project": "__NAME__",
  "description": "TODO: describe this project / feature set",
  "features": [
    {
      "id": 1,
      "category": "architecture",
      "description": "TODO: first architectural or setup task",
      "steps": [
        "Step 1: describe acceptance criterion",
        "Step 2: describe acceptance criterion"
      ],
      "passes": false
    },
    {
      "id": 2,
      "category": "functional",
      "description": "TODO: core feature description",
      "steps": [
        "Step 1: describe acceptance criterion",
        "Step 2: describe acceptance criterion"
      ],
      "passes": false
    }
  ],
  "feedback_loops": [
    "npm run typecheck  (or: tsc --noEmit / mypy . / cargo check)",
    "npm test           (or: pytest / cargo test / go test ./...)",
    "npm run lint       (or: eslint . / ruff check . / clippy)"
  ],
  "done_criteria": "All features have passes=true and all feedback loops are green."
}
'@

# 4. progress.txt
$progress = @'
# __NAME__ Progress Log
# Claude appends one entry here after each iteration.
# Format: [Iteration N | YYYY-MM-DD] Task | Files changed | Key decisions | Blockers
# Delete this file when your sprint is done - it is session-specific, not permanent docs.
# -----------------------------------------------------------------------

'@

# 5. AGENTS.md
$agents = @'
# __NAME__ - Agent Quality Expectations

## Role
You are a focused, iterative software engineer working on **__NAME__**.
Each run: pick ONE task, complete it fully, verify it, commit.

## Task Priority Order
1. Architectural decisions and core abstractions
2. Integration points between modules
3. Unknown unknowns / spike / research
4. Standard feature implementation
5. Polish, cleanup, quick wins

## Repo Type
<!-- Pick one and delete the others -->
- **Prototype** - speed over perfection, shortcuts OK
- **Production** - maintainable, tested, no shortcuts
- **Library** - public API, backward compatibility matters

## Quality Bar
- No stubs. Every implementation must be complete and working.
- No partial work. If a task is too large, scope it smaller.
- Run all feedback loops **before** committing. Fix failures first.
- Commits must explain *why*, not just *what*.
- Fight entropy - leave the codebase better than you found it.

## Feedback Loops (non-negotiable)
Update these commands for your stack:

| Loop  | Command                                        |
|-------|------------------------------------------------|
| Types | `tsc --noEmit` / `mypy .` / `cargo check`     |
| Tests | `npm test` / `pytest` / `cargo test`           |
| Lint  | `eslint .` / `ruff check .` / `cargo clippy`  |

## Step Size
- One logical change per commit.
- If a task feels large, break it into sub-tasks first.
- Prefer multiple small commits over one big one.
- Smaller steps = tighter feedback = higher quality.

## Progress Log
After each run, append to `__NAME__-progress.txt`:

```
[Iteration N | YYYY-MM-DD]
Task: <what you worked on>
Files changed: <list>
Key decisions: <rationale - concise, sacrifice grammar>
Blockers: <any blockers, or "none">
```

## Completion Signal
When **all** features in the PRD have `"passes": true` and all feedback loops pass,
output exactly: `<promise>COMPLETE</promise>`
'@

# ---------------------------------------------------------------------------
# Write files (replace __NAME__ placeholder, UTF8 no BOM for compatibility)
# ---------------------------------------------------------------------------
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$files = [ordered]@{
    "$dir/$name-ralph-once.ps1" = $ralphOncePs1 -replace '__NAME__', $name
    "$dir/$name-ralph-once.sh"  = $ralphOnceSh  -replace '__NAME__', $name
    "$dir/$name-prd.json"       = $prd           -replace '__NAME__', $name
    "$dir/$name-progress.txt"   = $progress      -replace '__NAME__', $name
    "$dir/$name-AGENTS.md"      = $agents        -replace '__NAME__', $name
}

foreach ($entry in $files.GetEnumerator()) {
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location) $entry.Key),
        $entry.Value,
        $utf8NoBom
    )
    Write-Host "  created: $($entry.Key)"
}

Write-Host ""
Write-Host "Ralph HITL scaffolded: ./$dir/$name"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit ./$dir/$name-prd.json    - fill in your features"
Write-Host "  2. Edit ./$dir/$name-AGENTS.md   - pick repo type, update feedback loop commands"
Write-Host "  3. Run one HITL iteration:"
Write-Host ""
Write-Host "     PowerShell (Windows):"
Write-Host "       powershell -ExecutionPolicy Bypass -File ./$dir/$name-ralph-once.ps1"
Write-Host ""
Write-Host "     Git Bash / WSL / macOS:"
Write-Host "       bash ./$dir/$name-ralph-once.sh"
Write-Host ""
Write-Host "To install globally (run from any project):"
Write-Host "  Copy-Item new-ralph-loop.ps1 `"`$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.ps1`""
Write-Host "  Copy-Item new-ralph-loop.bat `"`$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.bat`""
