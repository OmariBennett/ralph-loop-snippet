# test - Agent Quality Expectations

## Role
You are a focused, iterative software engineer working on **test**.
Each run: pick ONE task, complete it fully, verify it, commit.

## Task Priority Order
1. Architectural decisions and core abstractions
2. Integration points between modules
3. Unknown unknowns / spike / research
4. Standard feature implementation
5. Polish, cleanup, quick wins

## Repo Type
- **Prototype** - speed over perfection, shortcuts OK

## Quality Bar
- No stubs. Every implementation must be complete and working.
- No partial work. If a task is too large, scope it smaller.
- Run all feedback loops **before** committing. Fix failures first.
- Commits must explain *why*, not just *what*.

## Feedback Loops (non-negotiable)

This project uses simple PowerShell commands as feedback loops since there is no build system.
Replace these with real commands once you adopt a real stack.

### How to set up feedback loops for your stack

**Step 1 - Pick your stack's commands:**

| Loop  | Node/TypeScript         | Python          | Rust              | Go                |
|-------|-------------------------|-----------------|-------------------|-------------------|
| Types | `tsc --noEmit`          | `mypy .`        | `cargo check`     | `go build ./...`  |
| Tests | `npm test`              | `pytest`        | `cargo test`      | `go test ./...`   |
| Lint  | `eslint .` / `biome .`  | `ruff check .`  | `cargo clippy`    | `go vet ./...`    |

**Step 2 - Verify each command exits 0 (success) before adding it:**
```powershell
tsc --noEmit; echo $LASTEXITCODE   # should print 0
```

**Step 3 - Update the `feedback_loops` array in the prd.json with the exact commands.**

**Step 4 - Update the table below to match your project.**

### Current feedback loops for this test scaffold

| Loop  | Command                                                       |
|-------|---------------------------------------------------------------|
| Types | `pwsh -Command "if (Test-Path test/hello.txt) { Write-Output 'types OK' } else { throw 'hello.txt missing' }"` |
| Tests | `pwsh -Command "Write-Output 'tests OK'"` |
| Lint  | `pwsh -Command "Write-Output 'lint OK'"` |

## Step Size
- One logical change per commit.
- If a task feels large, break it into sub-tasks first.
- Prefer multiple small commits over one big one.

## Progress Log
After each run, append to `test-progress.txt`:

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
