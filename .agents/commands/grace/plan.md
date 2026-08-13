---
description: "Run GRACE architectural planning — design modules, contracts, data flows, verification"
---

Load the `grace-plan` skill and follow its instructions to design the module architecture.

Prerequisites:
- `docs/requirements.xml` must exist
- `docs/technology.xml` must exist
- If missing, tell the user to run `/grace:init` first

Process:
1. Read the `grace-plan` SKILL.md from `.agents/skills/grace-plan/`
2. Phase 1: Analyze requirements from `docs/requirements.xml`
3. Phase 2: Design module architecture (present to user, wait for approval)
4. Phase 3: Design verification surfaces
5. Phase 4: Mental walkthroughs for key scenarios
6. Phase 5: Generate artifacts (`development-plan.xml`, `verification-plan.xml`, `knowledge-graph.xml`)
7. Suggest next step: `/grace:execute` or `/grace:execute-parallel`
