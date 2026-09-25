---
description: "Sync GRACE shared artifacts with the actual codebase (targeted or full refresh)"
---

Load the `grace-refresh` skill and follow its instructions to synchronize artifacts.

Modes:
- `targeted` (default) — scan only changed modules and affected dependencies
- `full` — scan entire codebase, use after refactors or when drift is suspected

Process:
1. Read the `grace-refresh` SKILL.md from `.agents/skills/grace-refresh/`
2. Determine refresh scope based on context (targeted vs full)
3. Scan codebase and compare with `docs/knowledge-graph.xml`, `docs/verification-plan.xml`
4. Update artifacts to match actual code state
5. Report drift found and fixes applied
