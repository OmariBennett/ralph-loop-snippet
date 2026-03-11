#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scaffolds a Ralph loop (HITL) for any project.

.DESCRIPTION
    Creates a folder with 5 files for a human-in-the-loop Ralph iteration workflow.
    Copy this script to any directory on your $PATH to use globally.

.PARAMETER LoopPath
    Format: <namespace>/<name>  (e.g. "todo/todo" or "myapp/auth")

.EXAMPLE
    ./new-ralph-loop.ps1 todo/todo
    ./new-ralph-loop.ps1 myapp/auth
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$LoopPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Parse argument ---
# Accept either "name" (shorthand for "name/name") or "namespace/name"
if ($LoopPath -match '^([^/]+)/([^/]+)$') {
    $namespace = $Matches[1]
    $name      = $Matches[2]
} elseif ($LoopPath -match '^([^/]+)$') {
    $namespace = $Matches[1]
    $name      = $Matches[1]
} else {
    Write-Error "Argument must be a name (e.g. foo) or namespace/name (e.g. foo/foo)"
    exit 1
}
$dir = $namespace

# --- Create directory ---
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
}

# ─────────────────────────────────────────────
# File templates — use __NAME__ as placeholder
# Single-quoted here-strings prevent PS interpolation
# ─────────────────────────────────────────────

# 1. ralph-once.sh  (PRIMARY — HITL runner)
$ralphOnce = @'
#!/usr/bin/env bash
# __NAME__-ralph-once.sh — HITL single-iteration runner
# Run this once, watch what Claude does, intervene when needed.
# Refine the PRD or prompt between runs before going AFK.
#
# Usage:
#   bash __NAME__-ralph-once.sh
#
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD="${DIR}/__NAME__-prd.json"
PROGRESS="${DIR}/__NAME__-progress.txt"

if [[ ! -f "$PRD" ]]; then
  echo "ERROR: $PRD not found" >&2
  exit 1
fi

echo "==> Ralph HITL — single iteration for: __NAME__"
echo "    PRD:      $PRD"
echo "    Progress: $PROGRESS"
echo ""

result=$(claude -p \
"@${PRD} @${PROGRESS}
1. Decide which task to work on next — highest priority by YOUR judgment, not list order.
2. Check feedback loops (types, tests, lint) before and after changes.
3. Append your progress to __NAME__-progress.txt (date, task, files changed, decisions, blockers).
4. Make a git commit of that feature with a descriptive message.
ONLY WORK ON A SINGLE FEATURE PER RUN.
If, while implementing the feature, you notice that all work is complete, output <promise>COMPLETE</promise>.")

echo "$result"

if echo "$result" | grep -q '<promise>COMPLETE</promise>'; then
  echo ""
  echo "==> COMPLETE signal received. All features done."
fi
'@

# 2. ralph.ps1  (full loop runner)
$ralphLoop = @'
#!/usr/bin/env pwsh
# __NAME__-ralph.ps1 — Full loop runner (AFK mode)
# Run ralph-once.sh repeatedly up to MaxIterations.
# Prefer ralph-once.sh for HITL / prompt refinement first.
#
# Usage:
#   pwsh __NAME__-ralph.ps1 [-MaxIterations 10]
#
param(
    [int]$MaxIterations = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$runnerScript  = Join-Path $scriptDir "__NAME__-ralph-once.sh"

if (-not (Test-Path $runnerScript)) {
    Write-Error "Runner not found: $runnerScript"
    exit 1
}

Write-Host "==> Ralph loop starting: __NAME__ (max $MaxIterations iterations)"

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host ""
    Write-Host "--- Iteration $i / $MaxIterations ---"

    $result = bash "$runnerScript" 2>&1
    Write-Host $result

    if ($result -match '<promise>COMPLETE</promise>') {
        Write-Host ""
        Write-Host "==> COMPLETE after $i iteration(s)."
        exit 0
    }
}

Write-Host ""
Write-Host "==> Reached max iterations ($MaxIterations). Review progress and re-run."
'@

# 3. prd.json
$prd = @'
{
  "project": "__NAME__",
  "description": "TODO: describe this project/feature set",
  "features": [
    {
      "id": 1,
      "category": "architecture",
      "description": "TODO: first architectural decision or setup task",
      "steps": [
        "Step 1",
        "Step 2"
      ],
      "passes": false
    },
    {
      "id": 2,
      "category": "functional",
      "description": "TODO: core feature description",
      "steps": [
        "Step 1",
        "Step 2"
      ],
      "passes": false
    }
  ],
  "feedback_loops": [
    "Run type checker (tsc / mypy / etc.)",
    "Run unit tests",
    "Run linter"
  ],
  "done_criteria": "All features have passes=true and all feedback loops are green."
}
'@

# 4. progress.txt
$progress = @'
# __NAME__ Progress Log
# Claude appends an entry here after each iteration.
# Format: [Iteration N | DATE] Task | Files changed | Decisions | Blockers
# ─────────────────────────────────────────────────────────────────────────

'@

# 5. AGENTS.md
$agents = @'
# __NAME__ — Agent Quality Expectations

## Role
You are a focused, iterative software engineer working on **__NAME__**.
Each run you pick **one** task, complete it fully, verify it, and commit.

## Task Priority Order
1. Architectural decisions & foundational setup
2. Integration points between components
3. Unknown unknowns / spike / research tasks
4. Standard feature implementation
5. Polish, refactoring, quick wins

## Quality Bar
- **No stubs.** Every implementation must be complete and working.
- **No partial work.** If a feature cannot be finished in one run, scope it smaller.
- Run all feedback loops (types, tests, lint) **before marking a task done**.
- Commits must have descriptive messages explaining *why*, not just *what*.

## Feedback Loops (non-negotiable)
Run these after every change. Fix failures before committing.

| Loop  | Command (adjust per stack)            |
|-------|---------------------------------------|
| Types | `tsc --noEmit` / `mypy .` / `cargo check` |
| Tests | `npm test` / `pytest` / `cargo test`  |
| Lint  | `eslint .` / `ruff check .` / `clippy` |

## Progress Log Format
Append to `__NAME__-progress.txt` after each run:

```
[Iteration N | YYYY-MM-DD]
Task: <what you worked on>
Files changed: <list>
Key decisions: <rationale>
Blockers: <any blockers, or "none">
```

## Completion Signal
When **all** features in the PRD have `"passes": true` and all feedback loops are green,
output exactly: `<promise>COMPLETE</promise>`
'@

# ─────────────────────────────────────────────
# Substitute placeholder and write files
# ─────────────────────────────────────────────
$files = [ordered]@{
    "$dir/$name-ralph-once.sh" = $ralphOnce  -replace '__NAME__', $name
    "$dir/$name-ralph.ps1"     = $ralphLoop  -replace '__NAME__', $name
    "$dir/$name-prd.json"      = $prd        -replace '__NAME__', $name
    "$dir/$name-progress.txt"  = $progress   -replace '__NAME__', $name
    "$dir/$name-AGENTS.md"     = $agents     -replace '__NAME__', $name
}

foreach ($entry in $files.GetEnumerator()) {
    Set-Content -Path $entry.Key -Value $entry.Value -Encoding UTF8 -NoNewline
    Write-Host "  created: $($entry.Key)"
}

# Make ralph-once.sh executable (useful on Linux/macOS/WSL)
$platform = if ($PSVersionTable.PSEdition -eq 'Core') { $PSVersionTable.Platform } else { 'Win32NT' }
if ($platform -ne 'Win32NT') {
    chmod +x "$dir/$name-ralph-once.sh"
}

Write-Host ""
Write-Host "Ralph loop scaffolded for '$name' in ./$dir/"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit ./$dir/$name-prd.json  — fill in your features"
Write-Host "  2. Edit ./$dir/$name-AGENTS.md — adjust feedback loop commands for your stack"
Write-Host "  3. Run one HITL iteration (watch and intervene as needed):"
Write-Host "       bash ./$dir/$name-ralph-once.sh"
Write-Host ""
Write-Host "To install globally, copy this script to a directory on your PATH:"
Write-Host "  Copy-Item ./new-ralph-loop.ps1 `$HOME/.local/bin/new-ralph-loop.ps1"
