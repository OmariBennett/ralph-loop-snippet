# new-ralph.ps1
# Usage: .\new-ralph.ps1 <project-name>
# Scaffolds a HITL Ralph loop project with all components.

param(
    [Parameter(Position=0)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

if (-not $Name) {
    Write-Host "Usage: .\new-ralph.ps1 <project-name>"
    Write-Host "Example: .\new-ralph.ps1 my-app"
    exit 1
}

$Dir = ".\$Name"
$AbsDir = Join-Path (Get-Location) $Name

if (Test-Path $Dir) {
    Write-Host "Error: Directory '$Dir' already exists."
    exit 1
}

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

Write-Host "Creating HITL Ralph loop project: $Name"

# Write with LF line endings (required for bash scripts run in Git Bash)
function Write-Utf8Lf {
    param([string]$Path, [string]$Content)
    $Content = $Content -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

# ─── ralph-once.sh ───────────────────────────────────────────────────────────
$ralphOnce = @'
#!/usr/bin/env bash
# HITL Ralph — run once, watch, intervene.
# Usage: ./<name>-ralph-once.sh
#
# How it works: Single iteration. Watch Claude work, intervene if needed.
# Best for:    Learning, prompt refinement, pair-programming style.
#
# Cleanup: Delete <name>-progress.txt after the sprint is complete.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD="$SCRIPT_DIR/PROJECT_NAME-prd.json"
PROGRESS="$SCRIPT_DIR/PROJECT_NAME-progress.txt"

# Ensure progress file exists
touch "$PROGRESS"

result=$(claude -p \
"@$PRD @$PROGRESS

You are working on the PROJECT_NAME project.

Steps:
1. Read the PRD (@PROJECT_NAME-prd.json) and progress file (@PROJECT_NAME-progress.txt).
2. Decide which task has the HIGHEST priority (not necessarily the first).
   - Prioritize: architectural decisions > integration points > features > polish.
3. Take ONE small, focused step. One logical change per commit.
4. Run ALL feedback loops before committing:
   - TypeScript: npm run typecheck (must pass, zero errors)
   - Tests:      npm run test      (must pass)
   - Lint:       npm run lint      (must pass)
   DO NOT commit if any loop fails. Fix issues first.
5. Append a concise note to PROJECT_NAME-progress.txt:
   [$(date +%Y-%m-%d)] <task> — <what was done>, <decisions>, <blockers>
6. Make a git commit of that single change.
7. If ALL items in the PRD have passes=true, output exactly:
   <promise>COMPLETE</promise>

ONLY work on a single feature per run. Small steps compound.")

echo "$result"

if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
  echo ""
  echo "PRD complete! All tasks done."
  echo "Cleanup: delete $PROGRESS when sprint is finished."
  exit 0
fi
'@
$ralphOnce = $ralphOnce -replace 'PROJECT_NAME', $Name
Write-Utf8Lf (Join-Path $AbsDir "$Name-ralph-once.sh") $ralphOnce

# ─── prd.json ────────────────────────────────────────────────────────────────
$prd = @'
[
  {
    "category": "functional",
    "description": "TODO: describe your first feature here",
    "steps": [
      "Step 1: describe acceptance criteria",
      "Step 2: describe acceptance criteria",
      "Step 3: verify expected outcome"
    ],
    "passes": false
  },
  {
    "category": "functional",
    "description": "TODO: describe your second feature here",
    "steps": [
      "Step 1: describe acceptance criteria",
      "Step 2: verify expected outcome"
    ],
    "passes": false
  }
]
'@
Set-Content -Path (Join-Path $AbsDir "$Name-prd.json") -Value $prd -Encoding UTF8

# ─── progress.txt ─────────────────────────────────────────────────────────────
$progressContent = @"
# Progress — $Name
# Format: [YYYY-MM-DD] task — what was done, decisions made, blockers hit
# Tip: Sacrifice grammar for concision. Ralph reads this to skip re-exploration.
# Cleanup: DELETE this file after the sprint is complete (it is session-specific).

"@
Set-Content -Path (Join-Path $AbsDir "$Name-progress.txt") -Value $progressContent -Encoding UTF8

# ─── AGENTS.md ────────────────────────────────────────────────────────────────
$agentsContent = @'
# AGENTS.md — PROJECT_NAME

## Repo Type
<!-- Choose one and delete the others -->
- **Prototype**: Speed over perfection. Shortcuts acceptable. Skip edge cases.
- **Production**: Maintainable, tested, follows best practices. No shortcuts.
- **Library**: Public API matters. Backward compatibility required.

## Quality Expectation
This codebase will outlive you. Every shortcut becomes someone's burden.
Every hack compounds technical debt. Patterns you establish will be copied.
Corners you cut will be cut again. Fight entropy. Leave it better than you found it.

## Feedback Loops (run ALL before every commit)
| Loop               | Command               | Catches                        |
|--------------------|-----------------------|-------------------------------|
| TypeScript types   | npm run typecheck     | Type mismatches, missing props |
| Unit tests         | npm run test          | Broken logic, regressions      |
| Playwright MCP     | (configure as needed) | UI bugs, broken interactions   |
| ESLint / linting   | npm run lint          | Code style, potential bugs     |
| Pre-commit hooks   | (auto via git hook)   | Blocks bad commits entirely    |

**Rule**: Do NOT commit if any loop fails. Fix the issue first.

## Step Size
- One logical change per commit.
- If a task feels too large, break it into subtasks.
- Prefer multiple small commits over one large commit.
- Small steps compound. Quality over speed.

## Task Priority Order
1. Architectural decisions and core abstractions (highest risk — do first)
2. Integration points between modules (reveals incompatibilities early)
3. Unknown unknowns / spike work (fail fast)
4. Standard features and implementation
5. Polish, cleanup, quick wins (lowest risk — do last)

## Scope Rules
- Only implement what is in PROJECT_NAME-prd.json.
- When a PRD item is complete, set "passes": true.
- Emit `<promise>COMPLETE</promise>` only when ALL items have passes=true.
- Do not skip items marked "internal-only" unless PRD explicitly says so.
'@
$agentsContent = $agentsContent -replace 'PROJECT_NAME', $Name
Set-Content -Path (Join-Path $AbsDir "$Name-AGENTS.md") -Value $agentsContent -Encoding UTF8

# ─── Summary ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Done! Created: $Dir\"
Write-Host ""
Write-Host "  $Name-ralph-once.sh   -- HITL runner (run once, watch, intervene)"
Write-Host "  $Name-prd.json        -- PRD template (fill in your features)"
Write-Host "  $Name-progress.txt    -- Progress tracker (delete after sprint)"
Write-Host "  $Name-AGENTS.md       -- Quality expectations + feedback loops"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit $Name-prd.json -- define your features"
Write-Host "  2. Edit $Name-AGENTS.md -- set repo type + feedback loop commands"
Write-Host "  3. Run: cd $Dir && bash $Name-ralph-once.sh"
Write-Host "  4. Watch, intervene if needed, repeat."
Write-Host "  5. Delete $Name-progress.txt when sprint is complete (cleanup)."
