---
description: "Show GRACE project health — artifacts, metrics, graph, verification coverage"
---

Load the `grace-status` skill and report the current state of the GRACE project.

Report includes:
1. Artifacts status (AGENTS.md, knowledge-graph.xml, requirements.xml, technology.xml, development-plan.xml, verification-plan.xml)
2. Codebase metrics (source files, test files, MODULE_CONTRACT coverage, semantic blocks)
3. Knowledge graph health (module count, crosslinks, annotations)
4. Verification coverage (test coverage, verification entries)
5. Suggested next actions

When the `grace` CLI is available, prefer `grace status --path <project-root>`.
