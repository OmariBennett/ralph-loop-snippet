# How to Use new-ralph-loop

Scaffold a HITL Ralph loop for any project on Windows.

---

## Prerequisites

- Windows with PowerShell
- `claude` CLI installed and on your PATH

---

## One-Time Global Install

Copy both files to a directory on your PATH so `new-ralph-loop` works from any project:

```powershell
Copy-Item .\new-ralph-loop.ps1 "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.ps1"
Copy-Item .\new-ralph-loop.bat "$HOME\AppData\Local\Microsoft\WindowsApps\new-ralph-loop.bat"
```

Restart your terminal. You can now run `new-ralph-loop` from anywhere.

---

## Step 1 - Scaffold a New Loop

Navigate to your project root, then run:

```powershell
new-ralph-loop <name>/<name>
```

**Example:**

```powershell
cd C:\your\project
new-ralph-loop todo/todo
```

This creates a `todo\` folder with 5 files:

| File | Purpose |
|------|---------|
| `todo-ralph-once.ps1` | HITL runner (Windows / PowerShell) |
| `todo-ralph-once.sh` | HITL runner (Git Bash / WSL / macOS) |
| `todo-prd.json` | PRD - define your features here |
| `todo-progress.txt` | Progress tracker - Claude appends here |
| `todo-AGENTS.md` | Quality expectations + feedback loop commands |

---

## Step 2 - Define Your Features in the PRD

Open `todo-prd.json` and replace the placeholder entries:

```json
{
  "project": "todo",
  "description": "Describe this project / feature set",
  "features": [
    {
      "id": 1,
      "category": "functional",
      "description": "User can log in with email and password",
      "steps": [
        "POST /auth/login returns a JWT on valid credentials",
        "Invalid credentials return 401"
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
```

- Each feature starts with `"passes": false`
- Claude sets it to `true` when the feature is complete
- Claude emits `<promise>COMPLETE</promise>` when all features pass

---

## Step 3 - Configure AGENTS.md

Open `todo-AGENTS.md` and:

1. Pick your repo type (Prototype / Production / Library) and delete the others
2. Update the feedback loop commands to match your stack

**Examples by stack:**

| Stack | Typecheck | Tests | Lint |
|-------|-----------|-------|------|
| Node/TS | `tsc --noEmit` | `npm test` | `eslint .` |
| Python | `mypy .` | `pytest` | `ruff check .` |
| Rust | `cargo check` | `cargo test` | `cargo clippy` |

---

## Step 4 - Run One HITL Iteration

Watch Claude work. Intervene if it goes off track.

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -File .\todo\todo-ralph-once.ps1
```

**Git Bash / WSL / macOS:**

```bash
bash ./todo/todo-ralph-once.sh
```

Each iteration Claude will:
1. Read the PRD and progress file
2. Pick the highest-priority incomplete feature
3. Implement it (one feature only)
4. Run feedback loops - fix any failures before committing
5. Append a dated entry to `todo-progress.txt`
6. Make a git commit
7. Emit `<promise>COMPLETE</promise>` if all features are done

---

## Step 5 - Review and Repeat

- Check the commit Claude made
- If something is wrong, fix it or revert, then re-run
- Adjust the PRD mid-sprint if needed - set `"passes": false` to redo a feature
- Re-run the runner for the next feature

---

## Cleanup

When your sprint is done, delete `progress.txt` - it is session-specific, not permanent documentation.

```powershell
Remove-Item .\todo\todo-progress.txt
```

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `claude: command not found` | Install the Claude CLI and ensure it is on your PATH |
| `cannot be loaded, running scripts is disabled` | Use the `.bat` wrapper instead of calling `.ps1` directly |
| `@file not found` | The script uses `Push-Location` to fix this automatically - make sure you are using the generated `ralph-once.ps1`, not an old version |
| PRD not found | Run the runner from any directory - it resolves paths from the script's own location |
