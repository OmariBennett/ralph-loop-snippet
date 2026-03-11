# new-ralph.ps1 — HITL Ralph Loop Scaffold Generator

## What It Does
`new-ralph.ps1 <project-name>` auto-generates all components for a HITL Ralph loop project, based on the [11 Tips For AI Coding With Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).

**HITL** (human-in-the-loop): run once, watch, intervene. Best for learning and prompt refinement.

## Usage

```powershell
.\new-ralph.ps1 <project-name>
# Example:
.\new-ralph.ps1 my-app

# With git worktree:
.\new-ralph.ps1 my-app -Worktree -Branch jaragua-lizard
```

## Checklist / Outline

- [ ] `new-ralph.ps1` — PowerShell generator script (root of repo)
- [ ] `<name>/<name>-ralph-once.sh` — HITL single-iteration runner
- [ ] `<name>/<name>-prd.json` — PRD template (JSON format)
- [ ] `<name>/<name>-progress.txt` — blank progress tracker
- [ ] `<name>/<name>-AGENTS.md` — quality expectations + feedback loops
- [ ] `<name>/docker-example.txt` — Docker explainer (junior dev)
- [ ] `<name>/docker-compose-example.txt` — Docker Compose explainer (junior dev)

## Generated Files

### `<name>-ralph-once.sh`
HITL runner. Run once, watch Claude work, intervene if needed.
- Uses `docker sandbox run claude` (sandbox isolates Claude from home dir/SSH keys)
- Prompt: read PRD + progress → pick highest-priority task → run feedback loops → append progress → git commit → emit `<promise>COMPLETE</promise>` if done
- Cleanup: delete `progress.txt` after sprint

### `<name>-prd.json`
Define your scope. JSON format with acceptance criteria per feature.
```json
[
  {
    "category": "functional",
    "description": "TODO: describe feature",
    "steps": ["Step 1", "Step 2"],
    "passes": false
  }
]
```
Set `"passes": true` when a feature is complete. Ralph emits `COMPLETE` when all items pass.

### `<name>-progress.txt`
Session progress tracker. Ralph reads it each iteration to skip re-exploration.
```
# Format: [date] task — what was done, decisions, blockers
```
Delete after sprint is complete (session-specific, not permanent docs).

### `<name>-AGENTS.md`
Quality expectations Ralph reads every iteration:
1. Repo type (prototype / production / library)
2. Feedback loops (typecheck, test, lint, pre-commit hooks)
3. Step size rule (one logical change per commit)
4. Priority order (arch → integration → features → polish)
5. Quality expectation: fight entropy, leave it better than you found it

### `docker-example.txt`
Plain-English Docker walkthrough for junior devs:
- What a Dockerfile is (recipe for your app's environment)
- Key instructions: `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `CMD`
- How `docker sandbox run` isolates Claude (mounts CWD, blocks home dir/SSH)

### `docker-compose-example.txt`
Plain-English Docker Compose walkthrough for junior devs:
- What docker-compose is (orchestrates multiple containers)
- Key sections: `services`, `volumes`, `ports`, `environment`
- Example: `app` + `db` service
- When to use: Ralph's project needs a database/backend for feedback loops

## Feedback Loops

| Loop | What It Catches |
|------|----------------|
| TypeScript types | Type mismatches, missing props |
| Unit tests | Broken logic, regressions |
| Playwright MCP server | UI bugs, broken interactions |
| ESLint / linting | Code style, potential bugs |
| Pre-commit hooks | Blocks bad commits entirely |

## Verification

1. `.\new-ralph.ps1 my-app` — creates `.\my-app\` with 6 files
2. `Test-Path my-app\my-app-ralph-once.sh` — confirm file exists
3. `Get-Content my-app\my-app-prd.json` — confirm valid JSON
4. `.\new-ralph.ps1` (no arg) — prints usage error
