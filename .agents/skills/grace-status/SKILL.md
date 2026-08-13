---
name: grace-status
description: "Show the current health status of a GRACE project. Use to get an overview of project artifacts, codebase metrics, knowledge graph health, verification coverage, and suggested next actions."
---

Show the current state of the GRACE project, including whether it is safe to hand to a longer autonomous run.

When the optional CLI is available, prefer `grace status --path <project-root>` for the initial report. Use `grace status --with modules --path <project-root>` when project-level health is not enough and you need module summaries before deeper investigation.

## Report Contents

### 1. Artifacts Status
Check existence and version of:
- [ ] `AGENTS.md` — GRACE principles
- [ ] `docs/knowledge-graph.xml` — version and module count
- [ ] `docs/requirements.xml` — version and UseCase count
- [ ] `docs/technology.xml` — version and stack summary
- [ ] `docs/development-plan.xml` — version and module count
- [ ] `docs/verification-plan.xml` — version and verification entry count
- [ ] `docs/operational-packets.xml` — optional packet template version

### 2. Codebase Metrics
Scan source files and report:
- Total source files
- Files WITH MODULE_CONTRACT
- Files WITHOUT MODULE_CONTRACT (warning)
- Total test files
- Test files WITH MODULE_CONTRACT
- Total semantic blocks (START_BLOCK / END_BLOCK pairs)
- Unpaired blocks (integrity violation)
- Files with stable log markers
- Test files that assert log markers or traces when relevant

### 3. Knowledge Graph and Verification Health
Quick check:
- Modules in graph vs modules in codebase
- Any orphaned or missing entries
- Modules in verification plan vs modules in development plan
- Missing or stale verification refs
- Pending phases and steps that still need execution
- Autonomy blockers from `grace lint --profile autonomous`

If the optional `grace` CLI is available, you may also run `grace lint --path <project-root>` as a fast integrity snapshot and include any relevant findings in the report.

If the report is specifically about autonomous execution readiness, also run `grace lint --profile autonomous --path <project-root>` and summarize blockers versus warnings.

When the report needs focused navigation instead of raw artifact dumps, you may also use:
- `grace module find <query> --path <project-root>` to resolve the relevant module from names, IDs, dependencies, or changed paths
- `grace module show M-XXX --path <project-root> --with verification,health` for the shared/public module snapshot
- `grace module health M-XXX --path <project-root>` for the module-scoped blockers, warnings, and next action
- `grace verification show V-M-XXX --path <project-root>` for the linked verification entry itself
- `grace file show <path> --path <project-root> --contracts --blocks` for the file-local/private markup snapshot

### 4. Recent Changes
List the 5 most recent CHANGE_SUMMARY entries across source and substantive test files.

### 5. Suggested Next Action
Based on the status, suggest what to do next:
- If no requirements — "Define requirements in docs/requirements.xml"
- If requirements but no plan — "Run `$grace-plan`"
- If plan exists but verification is still thin — "Run `$grace-verification`"
- If plan and verification are ready but modules are missing — "Run `$grace-execute` or `$grace-multiagent-execute`"
- If drift detected — "Run `$grace-refresh`"
- If fast integrity signals are needed before deeper review — "Run `grace lint --path <project-root>`"
- If one lint code needs direct remediation guidance — "Run `grace lint --explain <code>`"
- If the next step is targeted investigation of one module or file — "Run `grace module show M-XXX --path <project-root> --with verification` or `grace file show <path> --path <project-root> --contracts --blocks`"
- If tests or logs are too weak for autonomous work — "Run `$grace-verification`"
- If autonomy blockers are present — "Run `grace lint --profile autonomous --path <project-root>` and strengthen verification or packet quality before execution"
- If everything synced — "Project is healthy"
