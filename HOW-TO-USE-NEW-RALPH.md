# How to Use `new-ralph`

`new-ralph` scaffolds a HITL (Human-in-the-Loop) Ralph loop project — a structured way to have Claude work on your codebase one focused step at a time, with you watching and able to intervene.

---

## Prerequisites

- Windows Terminal with PowerShell
- `claude` CLI available in your PATH

---

## Installation (one-time)

Add `ralph-loop-snippet` to your PATH so `new-ralph` works from any directory:

```powershell
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Users\jelan\Desktop\ralph-loop-snippet", "User")
```

Then restart your terminal. You can now run `new-ralph` from anywhere.

> **How it works:** `new-ralph.bat` is a thin wrapper that calls `new-ralph.ps1` using its absolute path (`%~dp0new-ralph.ps1`), so the script always resolves correctly regardless of your working directory.

---

## Steps

### Step 1 — Scaffold a new project

```powershell
new-ralph <project-name>
```

**Example:**

```powershell
new-ralph my-app
```

**Outcome:** A new directory `./my-app/` is created containing:

| File | Purpose |
|---|---|
| `my-app-ralph-once.sh` | HITL runner — run once, watch, intervene |
| `my-app-prd.json` | PRD template — define your features here |
| `my-app-progress.txt` | Progress tracker — Claude appends notes here |
| `my-app-AGENTS.md` | Quality expectations and feedback loop commands |

---

### Step 2 — Define your features in the PRD

Open `my-app-prd.json` and replace the placeholder entries with your actual features and acceptance criteria.

```json
[
  {
    "category": "functional",
    "description": "User can log in with email and password",
    "steps": [
      "Step 1: POST /auth/login returns a JWT on valid credentials",
      "Step 2: Invalid credentials return 401",
      "Step 3: JWT is accepted by protected routes"
    ],
    "passes": false
  }
]
```

**Outcome:** Claude knows exactly what to build and in what order. Each item starts with `"passes": false`; Claude sets it to `true` when done.

---

### Step 3 — Set repo type and feedback loops in AGENTS.md

Open `my-app-AGENTS.md` and:

1. Choose a repo type (Prototype / Production / Library) — delete the others.
2. Confirm or update the feedback loop commands (`npm run typecheck`, `npm run test`, `npm run lint`) to match your project's actual scripts.

**Outcome:** Claude knows the quality bar and which commands to run before every commit.

---

### Step 4 — Run the HITL runner

```bash
cd my-app && bash my-app-ralph-once.sh
```

**Outcome:** Claude runs one focused iteration:

1. Reads the PRD and progress file.
2. Picks the highest-priority incomplete task.
3. Makes one small, focused change.
4. Runs all feedback loops (typecheck, tests, lint) — fixes any failures before committing.
5. Appends a dated note to `my-app-progress.txt`.
6. Makes a single git commit.
7. If all PRD items pass, outputs `<promise>COMPLETE</promise>` and exits.

You watch the output. If Claude goes off track, stop it and intervene before re-running.

---

### Step 5 — Repeat until complete

Re-run the script for each subsequent task:

```bash
bash my-app-ralph-once.sh
```

**Outcome:** Each run advances the project by one logical step. The progress file accumulates a running log of decisions and blockers, so Claude never re-explores what's already been done.

---

### Step 6 — Clean up after the sprint

When all PRD items are complete and the runner emits `COMPLETE`, delete the progress file:

```powershell
Remove-Item my-app-progress.txt
```

**Outcome:** The session-specific log is removed. The PRD, AGENTS.md, and committed code remain as the durable record of the project.

---

## Key Concepts

**HITL (Human-in-the-Loop):** You watch every run. You can stop and correct Claude between steps. Use `ralph-once.sh` — not a loop — so you review each iteration before the next begins.

**One step per run:** Each execution makes exactly one logical change and one commit. Small steps compound and are easier to review and revert.

**Feedback loops must pass:** Claude will not commit if `typecheck`, `test`, or `lint` fail. It fixes the issue first.

**PRD drives scope:** Claude only implements what is in the PRD. When an item is done, `"passes"` flips to `true`. When all items pass, the project is complete.
