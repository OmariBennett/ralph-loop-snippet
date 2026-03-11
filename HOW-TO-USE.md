# How to Use `new-ralph-loop`

Scaffolds a **HITL Ralph loop** for any project — one command creates everything you need to run Claude iteratively, watch its work, and step in when needed.

---

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated (`claude --version`)
- PowerShell (Windows PowerShell 5.1+ or PowerShell Core 7+)
- Bash (Git Bash, WSL, macOS/Linux terminal)

---

## Installation

### Option A — Use from this repo (one project)
```powershell
powershell.exe -ExecutionPolicy Bypass -File ./new-ralph-loop.ps1 <namespace>/<name>
```

### Option B — Install globally (all future projects)
Copy the script to any directory on your `$PATH`:
```powershell
Copy-Item ./new-ralph-loop.ps1 "$HOME/.local/bin/new-ralph-loop.ps1"

# Then from any repo:
new-ralph-loop.ps1 <namespace>/<name>
```

---

## Quickstart

```powershell
# 1. Scaffold a loop
powershell.exe -ExecutionPolicy Bypass -File ./new-ralph-loop.ps1 todo/todo

# 2. Fill in your features
#    Open todo/todo-prd.json and describe what you want Claude to build

# 3. Run one HITL iteration — watch, intervene as needed
bash todo/todo-ralph-once.sh
```

---

## Command Syntax

```
new-ralph-loop <namespace>/<name>
```

| Part | Description | Example |
|---|---|---|
| `namespace` | Folder to create | `todo` |
| `name` | Base name for all generated files | `todo` |

They can differ: `new-ralph-loop myapp/auth` creates `myapp/auth-*.{sh,ps1,...}`.

---

## Generated Files

Running `new-ralph-loop todo/todo` produces:

```
todo/
├── todo-ralph-once.sh    ← HITL runner (PRIMARY — use this first)
├── todo-ralph.ps1        ← AFK full loop runner
├── todo-prd.json         ← Feature list for Claude to work from
├── todo-progress.txt     ← Append-only log Claude writes each run
└── todo-AGENTS.md        ← Quality rules and feedback loop commands
```

### `todo-ralph-once.sh` — HITL Single-Iteration Runner

The primary file. Runs **one** Claude iteration. You watch everything it does and step in when needed.

```bash
bash todo/todo-ralph-once.sh
```

Claude will:
1. Read your PRD and progress log
2. Pick the highest-priority incomplete task
3. Run feedback loops (types, tests, lint)
4. Append a progress entry to `todo-progress.txt`
5. Make a git commit
6. Output `<promise>COMPLETE</promise>` if all features are done

### `todo-ralph.ps1` — Full Loop Runner (AFK)

Calls `ralph-once.sh` repeatedly up to a cap. Use this **after** HITL refinement, when the prompt is solid.

```powershell
pwsh todo/todo-ralph.ps1 -MaxIterations 10
```

Exits automatically when Claude outputs `<promise>COMPLETE</promise>`.

### `todo-prd.json` — Product Requirements Document

Describes what Claude should build. Edit this before your first run.

```json
{
  "project": "todo",
  "features": [
    {
      "id": 1,
      "category": "architecture",
      "description": "Set up project structure and dependencies",
      "steps": ["Initialize package.json", "Install dependencies"],
      "passes": false
    }
  ],
  "feedback_loops": ["tsc --noEmit", "npm test", "eslint ."]
}
```

Set `"passes": true` on a feature when Claude finishes it (or let Claude do it).

### `todo-progress.txt` — Progress Log

Claude appends here after each run. Review it between iterations to understand what happened.

```
[Iteration 1 | 2026-03-10]
Task: Initialize project structure
Files changed: package.json, tsconfig.json, src/index.ts
Key decisions: Used ESM modules for tree-shaking
Blockers: none
```

### `todo-AGENTS.md` — Agent Quality Rules

Tells Claude the quality bar, priority order, feedback loop commands for your stack, and the completion signal format. Edit the feedback loop commands to match your project.

---

## Recommended Workflow

```
┌─────────────────────────────────────────────────────┐
│  1. Scaffold    new-ralph-loop myproject/myfeature  │
│  2. Edit PRD    Add your features to -prd.json      │
│  3. Edit AGENTS Adjust feedback loop commands       │
│  4. HITL run    bash myfeature-ralph-once.sh        │
│     └─ Watch Claude, read its output                │
│     └─ Check git diff / git log                     │
│     └─ Edit PRD or prompt if needed                 │
│  5. Repeat step 4 until the prompt is solid         │
│  6. AFK run     pwsh myfeature-ralph.ps1 -Max 20   │
└─────────────────────────────────────────────────────┘
```

---

## Tips

**Start HITL, not AFK.**
Always do several `ralph-once.sh` runs first. Watch exactly what Claude does. Refine the PRD and `AGENTS.md` until Claude behaves correctly, then switch to the full loop.

**One feature per run.**
Claude is instructed to work on exactly one feature per iteration. Keep PRD features small and scoped.

**Git is your safety net.**
Claude commits after each feature. If a run goes wrong, `git reset --hard HEAD~1` to undo it.

**Feedback loops are non-negotiable.**
Claude won't mark a feature done until types, tests, and lint pass. Update the commands in `AGENTS.md` for your stack before the first run.

**Cap your iterations.**
`ralph.ps1` defaults to 10 iterations. Increase with `-MaxIterations 30` for larger tasks.
