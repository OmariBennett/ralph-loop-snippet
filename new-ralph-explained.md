# new-ralph — Script Breakdown

`new-ralph` is a PowerShell scaffold generator. Running `new-ralph <project-name>` (via `new-ralph.bat`) creates a ready-to-use HITL (Human-In-The-Loop) Ralph loop project directory.

The entry point is `new-ralph.bat`, a thin wrapper that resolves the absolute path to `new-ralph.ps1` using `%~dp0`, allowing the command to be called from any directory when `ralph-loop-snippet` is on your PATH.

---

## 0. File Encoding

`new-ralph.ps1` is saved as **UTF-8 with BOM** (`0xEF 0xBB 0xBF`). This is required because PowerShell 5.1 reads BOM-less files as Windows-1252, which misinterprets the em dash character `—` (UTF-8 bytes `E2 80 94`) — specifically, byte `0x94` decodes as U+201D (right curly quote `"`), which PowerShell treats as a closing string delimiter. Without the BOM, the final `Write-Host` strings are silently split mid-sentence, causing a `CommandNotFoundException` for `run`.

---

## 1. Header & Parameters (lines 1–8)

```powershell
# new-ralph.ps1
# Usage: new-ralph <project-name>

param(
    [Parameter(Position=0)]
    [string]$Name
)
```

Declares the script's single parameter: `$Name` is the project name passed as the first positional argument.

---

## 2. Strict Mode (line 10)

```powershell
$ErrorActionPreference = "Stop"
```

Causes PowerShell to throw a terminating error on any failure — equivalent to `set -e` in bash. Prevents silent errors from cascading.

---

## 3. Argument Validation (lines 12–16)

```powershell
if (-not $Name) {
    Write-Host "Usage: .\new-ralph.ps1 <project-name>"
    Write-Host "Example: .\new-ralph.ps1 my-app"
    exit 1
}
```

Exits with a usage message if no project name is provided. When invoked via `new-ralph.bat`, the usage hint still shows `.\new-ralph.ps1` — this is cosmetic and doesn't affect behaviour.

---

## 4. Directory Guard (lines 18–26)

```powershell
$Dir = ".\$Name"
$AbsDir = Join-Path (Get-Location) $Name

if (Test-Path $Dir) {
    Write-Host "Error: Directory '$Dir' already exists."
    exit 1
}
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
```

Prevents overwriting an existing directory. Creates the project folder only if it doesn't exist — equivalent to bash's `mkdir -p`. `$AbsDir` holds the absolute path used when writing files.

---

## 5. LF Line-Ending Helper (lines 31–36)

```powershell
function Write-Utf8Lf {
    param([string]$Path, [string]$Content)
    $Content = $Content -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}
```

Strips Windows CRLF line endings before writing. Used for `.sh` files so they run correctly inside Git Bash on Windows.

---

## 6. Generated File: `<name>-ralph-once.sh`

A single-iteration HITL runner written as a bash script. It:

- Reads the PRD (`<name>-prd.json`) and progress file (`<name>-progress.txt`) into Claude's context via `claude -p`.
- Instructs Claude to pick the **highest-priority** task (not just the first).
- Enforces a strict feedback loop before committing: TypeScript typecheck → tests → lint. Claude must not commit if any step fails.
- Appends a dated note to the progress file after each step.
- Exits cleanly when Claude emits `<promise>COMPLETE</promise>`, signaling all PRD items are done.

The template uses `@'...'@` (PowerShell literal here-string) so bash `$variables` are not expanded by PowerShell. After the here-string, `-replace 'PROJECT_NAME', $Name` substitutes the real project name. Written with `Write-Utf8Lf` to ensure LF line endings.

**Best used for:** learning, prompt refinement, pair-programming — you watch each run and can intervene.

---

## 7. Generated File: `<name>-prd.json`

A Product Requirements Document in JSON. Each entry has:

| Field | Purpose |
|---|---|
| `category` | Feature type (e.g. `"functional"`) |
| `description` | What the feature does |
| `steps` | Acceptance criteria Claude checks off |
| `passes` | Set to `true` by Claude when the item is complete |

Start by editing `TODO` descriptions with your actual features. Written with `Set-Content -Encoding UTF8`.

---

## 8. Generated File: `<name>-progress.txt`

A running log Claude reads at the start of each session to skip re-exploration. Format:

```
[YYYY-MM-DD] task — what was done, decisions made, blockers hit
```

Uses a `@"..."@` (PowerShell expandable here-string) so `$Name` is substituted directly.

**Delete this file after the sprint is complete** — it is session-specific context, not permanent documentation.

---

## 9. Generated File: `<name>-AGENTS.md`

Instructions for Claude's behavior during the project. Covers:

- **Repo type**: Prototype / Production / Library — choose one to set quality expectations.
- **Quality expectations**: Philosophical guidance against technical debt and shortcuts.
- **Feedback loops table**: Lists every quality gate (typecheck, tests, lint, Playwright, pre-commit) with its command and what it catches.
- **Step size rules**: One logical change per commit; break large tasks into subtasks.
- **Task priority order**: Architectural decisions first, polish last.
- **Scope rules**: Claude only works on items in the PRD, marks them `passes: true` when done, and emits `<promise>COMPLETE</promise>` only when all items pass.

Uses `@'...'@` + `-replace 'PROJECT_NAME', $Name` for substitution.

---

## 10. Summary Output

Prints a human-readable list of what was created and the recommended next steps:

1. Edit the PRD — define your features.
2. Edit `AGENTS.md` — set repo type and feedback loop commands.
3. Run `cd <name> && bash <name>-ralph-once.sh`.
4. Watch, intervene if needed, repeat.
5. Delete `<name>-progress.txt` when the sprint is complete.
