---
description: "Execute GRACE plan in parallel waves with multiple agents (controller + workers)"
---

Load the `grace-multiagent-execute` skill and follow its instructions for parallel execution.

Prerequisites:
- `docs/development-plan.xml` must exist with module contracts
- `docs/knowledge-graph.xml` must exist
- `docs/verification-plan.xml` should exist
- If missing, tell the user to run `/grace:plan` first

Process:
1. Read the `grace-multiagent-execute` SKILL.md from `.agents/skills/grace-multiagent-execute/`
2. Build execution waves (group parallel-safe steps)
3. Choose profile: safe / balanced (default) / fast
4. Present waves to user, wait for approval
5. Assign ownership: controller (shared artifacts), workers (module files), reviewers (read-only)
6. Dispatch fresh worker agents per wave
7. Review with smallest safe scope, integrate, sync graph
8. Print wave reports and final summary
