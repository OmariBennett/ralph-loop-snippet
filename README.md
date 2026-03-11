# new-ralph-loop - HITL Ralph Loop Scaffold Generator

Scaffolds a [Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) HITL (human-in-the-loop) workflow for any project on Windows.

**HITL**: run once, watch, intervene. Best for learning and prompt refinement.

## Files

| File | Purpose |
|------|---------|
| `new-ralph-loop.ps1` | Generator script |
| `new-ralph-loop.bat` | Windows wrapper (no execution policy hassle) |

## Usage

```powershell
# From this directory:
.\new-ralph-loop.bat todo/todo

# Or with PowerShell directly:
powershell -ExecutionPolicy Bypass -File .\new-ralph-loop.ps1 todo/todo

# Shorthand (todo -> todo/todo):
.\new-ralph-loop.bat todo
```

## What Gets Generated

Running `new-ralph-loop todo/todo` or `new-ralph-loop todo` creates `.\todo\` with:

| File | Purpose |
|------|---------|
| `todo-ralph-once.ps1` | HITL runner (Windows / PowerShell) |
| `todo-ralph-once.sh` | HITL runner (Git Bash / WSL / macOS) |
| `todo-prd.json` | PRD template - define features here |
| `todo-progress.txt` | Progress tracker - Claude appends here |
| `todo-AGENTS.md` | Quality expectations + feedback loop commands |

## Global Install

Copy both files to a directory on your PATH so `new-ralph-loop` works from any project:

```powershell
Copy-Item .\new-ralph-loop.ps1 "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.ps1"
Copy-Item .\new-ralph-loop.bat "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.bat"
```

Then restart your terminal and use from any directory:

```powershell
cd C:\your\other\project
new-ralph-loop myfeature/myfeature
# or shorthand:
new-ralph-loop myfeature
```

## Workflow

1. Generate: `new-ralph-loop myapp/myapp` or `new-ralph-loop myapp`
2. Edit `myapp-prd.json` - fill in your features with acceptance criteria
3. Edit `myapp-AGENTS.md` - pick repo type, update feedback loop commands for your stack
4. Run one iteration and watch:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\myapp\myapp-ralph-once.ps1
   ```
5. Intervene if needed, refine the PRD, run again

## PRD Format

```json
{
  "project": "myapp",
  "description": "Describe this project / feature set",
  "features": [
    {
      "id": 1,
      "category": "functional",
      "description": "User can log in",
      "steps": ["POST /auth/login returns JWT", "Invalid creds return 401"],
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
```

Set `"passes": true` when a feature is complete. Claude emits `<promise>COMPLETE</promise>` when all items pass.

## Why Push-Location?

Claude Code's `@filename` syntax resolves files **relative to the current working directory**. The generated `ralph-once.ps1` uses `Push-Location` into the project folder before calling claude, so `@todo-prd.json` always resolves correctly regardless of where you call the script from.
