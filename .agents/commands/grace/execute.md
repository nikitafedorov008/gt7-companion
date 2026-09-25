---
description: "Execute GRACE development plan sequentially — step by step with validation and commits"
---

Load the `grace-execute` skill and follow its instructions to implement modules step by step.

Prerequisites:
- `docs/development-plan.xml` must exist
- `docs/knowledge-graph.xml` must exist
- `docs/verification-plan.xml` should exist
- If missing, tell the user to run `/grace:plan` first

Process:
1. Read the `grace-execute` SKILL.md from `.agents/skills/grace-execute/`
2. Load and parse the plan once, build execution queue
3. Present queue to user, wait for approval
4. Execute each step sequentially: implement → review → verify → commit
5. Update shared artifacts after each step
6. Complete phases with broader checks
7. Print final summary
